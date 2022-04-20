SHELL = /bin/sh
# Actualizar con cada cambio
VERSION = 0.0.35

# Config
LATEX = latex
PDFLATEX = pdflatex
HTML_TOC_LEVEL = 2

# In/Out target names
INFILE = main
# html outfile
OUTFILE = index

# Colors codes
GREEN = \033[0;32m
ORANGE = \033[0;33m
NC = \033[0m

# =============================================================================

# Check all commands used
# Missing check: <perl URI::file> (perl MURI::file -e 1)
DEPENDENCIES = echo sed mkdir mv rm cp pdflatex make4ht latexmk tidy perl git 
K := $(foreach exec,$(DEPENDENCIES),\
		 $(if $(shell which $(exec)), OK, $(error "No $(exec) in PATH")))


# =============================================================================

default:
	@echo "Utilice 'make all', 'make pdf', 'make html', 'make sync' o 'make clean'."

all: logo pdf clean html sync

pdf: version latex_prepare latex2pdf_light latex_prepare latex2pdf

html: html_folders html_prepare html_convert html_tidy html_fix_classnames \
	  html_custom html_longtable_clean html_clean html_ok

local: pdf clean html

# =============================================================================

clean:
	@mkdir -p temp
	@mv $(INFILE).tex temp/
	@mv $(INFILE).pdf temp/
	-@mv $(INFILE)-print.pdf temp/
	-@mv $(INFILE).synctex.gz temp/
	-@mv $(INFILE)_build.fdb_latexmk temp/
	-@mv $(INFILE)-print_build.fdb_latexmk temp/
	-@rm $(INFILE).*
	-@rm $(INFILE)_build.*
	-@rm $(INFILE)-print_build.*
	@mv temp/* ./
	@rm -r temp

sync:
	@echo "Sincronizando GITHUB con la última versión de la documentación..."
	@git add .
	@git status
	@echo -e "..................................................\nSubiendo el commit:"
	@git commit -m "Auto uploaded v$(VERSION)"
	@git push
	@echo -e "..................................................\nSincronización exitosa."
	@echo -e "Version web en: ${ORANGE}https://polirritmico.github.io/Bakumapu-docs/${NC}"

links:
	@echo -en "HTML local en: ${ORANGE}"
	@echo -n '$(PWD)' | perl -MURI::file -e 'print URI::file->new(<>)'
	@echo -e "/docs/index.html${NC}"
	@echo -e "Version web en: ${ORANGE}https://polirritmico.github.io/Bakumapu-docs/${NC}"


# =============================================================================

latex_prepare:
	@echo -n "Preparando copia de $(INFILE).tex: "
	@cp $(INFILE).tex $(INFILE)_build.tex
	@echo -e "${GREEN}OK${NC}"

version:
	@echo -n "Ajustando la versión: "
	@sed -i '/\\newcommand{\\docversion}/s/{\\docversion}{\+.\+.\+}/{\\docversion}{$(VERSION)}/' $(INFILE).tex
	@echo -e "${GREEN}OK${NC}"

latex2pdf:
	@echo -e "Generando PDF a partir de ${ORANGE}$(INFILE).tex${NC}: "
	@latexmk -pdf -silent $(INFILE)_build.tex > /dev/null 2>&1
	@mv $(INFILE)_build.pdf $(INFILE).pdf
	@echo -e "${GREEN}OK${NC}\n${ORANGE}$(INFILE).pdf${NC} generado exitosamente."

latex2pdf_light:
	@cp ${INFILE}.tex ${INFILE}-print_build.tex
	@echo -n "Cambiando a esquema de color claro: "
	@sed -i '/\\newif\\ifdark\\/s/darktrue/darkfalse/' $(INFILE)-print_build.tex
	@echo -en "${GREEN}OK${NC}\nGenerando PDF-light a partir de ${ORANGE}$(INFILE).tex${NC}: "
	@latexmk -pdf -silent "$(INFILE)-print_build.tex" > /dev/null 2>&1
	@mv $(INFILE)-print_build.pdf $(INFILE)-print.pdf
	@echo -e "${GREEN}OK${NC}\n${ORANGE}$(INFILE)-print.pdf${NC} generado exitosamente."


# =============================================================================

html_folders:
	@mkdir -p build/config/style
	@cp -r config/style/* build
	@cp config/*.tex build/config/
	@cp -r images build/
	@cp -r secciones build/

html_prepare:
	@echo -n "Ajustando subtítulo: "
	@sed '/colorsubtitulo/s/{\\textsc{Diseño\ técnico}}/{Diseño\ técnico}/' $(INFILE).tex > build/$(OUTFILE).tex
	@echo -en "${GREEN}OK${NC}\nAjustando nivel de TOC a ${ORANGE}$(HTML_TOC_LEVEL)${NC} para el html: "
	@sed -i '/\\setcounter/s/{tocdepth}{*.}/{tocdepth}{$(HTML_TOC_LEVEL)}/' build/config/estilos.tex
	@echo -e "${GREEN}OK${NC}"

html_convert:
	@echo -e "Generando '${ORANGE}docs/$(OUTFILE).html${NC}' a partir de '${ORANGE}$(INFILE).tex${NC}'"
	@echo -e "Iniciando conversión:\n.................................................."
	@cd build && \
	make4ht -c custom.conf -d export/ $(OUTFILE).tex
	@echo -e "Conversión ${GREEN}OK${NC}"

html_tidy:
	@echo -n "Limpiando html con tidy: "
	@-cd build && \
	tidy -config tidy.conf export/$(OUTFILE).html > export/temp-$(OUTFILE).html
	@mv build/export/temp-$(OUTFILE).html build/export/$(OUTFILE).html
	@echo -e "Limpieza ${GREEN}OK${NC}"

html_fix_classnames:
	@echo -e "Leyendo nombres de clases..."
	$(MAKE) html_write_classnames TITLE_CLASSNAME=$(shell sed -n "s/.*<span class='\(.*\)'>Bakumapu<\/span>.*/\1/p" build/export/$(OUTFILE).html)

html_write_classnames:
	@echo -n "Ajustando nombres de clases: "
	@sed -i 's/MAIN_TITLE/$(TITLE_CLASSNAME)/' build/export/style.css
	@echo -e "${GREEN}OK${NC}"

html_custom:
	@echo -n "Ajustando título del HTML: "
	@sed -i 's/<title><\/title>/<title>Bakumapu v$(VERSION)<\/title>/' build/export/$(OUTFILE).html
	@echo -en "${GREEN}OK${NC}\nCorrigiendo espacios a comandos con signos '\$$': "
	@sed -i 's/$$<\/span><\/span>/$$ <\/span><\/span>/' build/export/$(OUTFILE).html
	@echo -en "${GREEN}OK${NC}\nAjustando espacios: "
	@sed -i '/<span/s/ / /g' build/export/$(OUTFILE).html
	@echo -en "${GREEN}OK${NC}\nAjustando links a target='_blank': "
	@sed -i -r "s/<a href='http([^>]*)'>/<a href='http\1' target='_blank'>/" build/export/$(OUTFILE).html
	@echo -en "${GREEN}OK${NC}\nAñadiendo botón al panel: "
	@sed -i "/<h3 class='likesectionHead'.*>/i \ \ \ \ <input type=\"checkbox\" id=\"showtoc\" checked><div class=\"tocbutton\"></div>" build/export/$(OUTFILE).html
	@echo -en "${GREEN}OK${NC}\nAjustando fracción: "
	@sed -i -r "s/Estudio <span class='(.+?)'>6<\/span><span class='(.+?)'>\/<\/span><span class='(.+?)'>8<\/span>/Estudio 6\/8/" build/export/$(OUTFILE).html
	@echo -en "${GREEN}Ok${NC}\nAgregando espacios a figuras: "
	@sed -i '/<span class='\''id'\''>Figura/s/<\/span>/ <\/span>/' build/export/$(OUTFILE).html
	@sed -i 's/Figura~/Figura /' build/export/$(OUTFILE).html
	@echo -en "${GREEN}OK${NC}\nAgregando fondo: "
	@cp images/fondo.jpg build/export/images/
	@echo -en "${GREEN}OK${NC}\nAgregando íconos: "
	@cp images/icon.svg build/export/images/
	@cp images/flecha.svg build/export/images/
	@sed -i '/\/head/i \ \ \ \ <link rel="icon" href="images\/icon.svg">' build/export/$(OUTFILE).html
	@echo -e "${GREEN}OK${NC}"

html_longtable_clean:
	@echo -n "Quitando comentarios html: "
	@perl -0777 -pi -e 's/\s*<!-- .*? -->\s*//g' build/export/$(OUTFILE).html
	@echo -en "${GREEN}OK${NC}\nAjustando longtable: "
	@perl -0777 -pi -e 's/\s*<p.*><\/p>\s*//g' build/export/$(OUTFILE).html
	@perl -0777 -pi -e 's/\s*<td.*>(\s*)?<\/td>\s*//g' build/export/$(OUTFILE).html
	@perl -0777 -pi -e 's/[ \t]*<tr.*>\s*<\/tr>[ \t]*\n//g' build/export/$(OUTFILE).html
	@echo -e "${GREEN}OK${NC}"

html_clean:
	@echo -en "Limpiando archivos de compilación: "
	@cd build && \
	rm -rf config images secciones
	@rm build/custom.conf build/tidy.conf build/$(OUTFILE).tex
	@rm build/$(OUTFILE).*
	@mv build/export/* build/
	@rm -r build/export
	@rm -rf docs && mv build docs
	@echo -e "${GREEN}OK${NC}\n.................................................."

html_ok:
	@echo -en "HTML generado exitosamente.\nRevisar en: ${ORANGE}"
	@echo -n '$(PWD)' | perl -MURI::file -e 'print URI::file->new(<>)'
	@echo -e "/docs/index.html${NC}"
	@echo "Usar 'make sync' para subir a GITHUB."


# =============================================================================

logo:
	@echo ""
	@echo -e "${GREEN}   ______   ______   __  __   __  __   __    __   ______   ______  __  __   "
	@echo "  /\  == \ /\  __ \ /\ \/ /  /\ \/\ \ /\ \"-./  \ /\  __ \ /\  == \/\ \/\ \  "
	@echo "  \ \  __< \ \  __ \\\\ \  _\"-.\ \ \_\ \\\\ \ \-./\ \\\\ \  __ \\\\ \  _-/\ \ \_\ \ "
	@echo "   \ \_____\\\ \_\ \_\\\\ \_\ \_\\\\ \_____\\\\ \_\ \ \_\\\\ \_\ \_\\\\ \_\   \ \_____\ "
	@echo "    \/_____/ \/_/\/_/ \/_/\/_/ \/_____/ \/_/  \/_/ \/_/\/_/ \/_/    \/_____/"
	@echo -e "${NC}"
	@echo "   ┌───────────────────────────────────────────────────────────────────────┐"
	@echo -e "   │${ORANGE}      E     S     T     U     D     I     O         6    /    8        ${NC}│"
	@echo "   └───────────────────────────────────────────────────────────────────────┘"
	@echo ""
	@echo ""

# @: Evita mostrar la llamada del comando en la salida.
# -@: Ignora los comandos que retornan non-successful status.
