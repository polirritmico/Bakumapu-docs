SHELL = /bin/sh
# Actualizar con cada cambio
VERSION = 0.0.19

# Define variables
LATEX = latex
PDFLATEX = pdflatex
HTML_TOC_LEVEL = 2

# In/Out target names
INFILE = main
OUTFILE = index

# Colors codes
GREEN = \033[0;32m
ORANGE = \033[0;33m
NC = \033[0m

default:
	@echo "Utilice 'make all', 'make pdf', 'make html', 'make version', 'make sync' o 'make clean'."

all: pdf clean html sync

pdf: version latex2pdf_light latex2pdf

version:
	@echo -n "Ajustando la versión: "
	@sed -i '/\\newcommand{\\docversion}/s/{\\docversion}{\+.\+.\+}/{\\docversion}{$(VERSION)}/' $(INFILE).tex
	@echo -e "${GREEN}OK${NC}"

clean:
	@mkdir -p temp
	@mv $(INFILE).tex temp/
	@mv $(INFILE).pdf temp/
	-@mv $(INFILE)-print.pdf temp/
	-@mv $(INFILE).synctex.gz temp/
	-@rm $(INFILE).*
	@mv temp/* ./
	@rm -r temp

latex2pdf:
	@echo -n "Cambiando a esquema de color oscuro: "
	@sed -i '/\\newif\\ifdark\\/s/darkfalse/darktrue/' $(INFILE).tex
	@echo -en "${GREEN}OK${NC}\nGenerando PDF a partir de ${ORANGE}$(INFILE).tex${NC}: "
	@pdflatex -synctex=1 -interaction=nonstopmode $(INFILE).tex 2>&1 > /dev/null
	@echo -en "1/3 ${GREEN}OK${NC} "
	@pdflatex -synctex=1 -interaction=nonstopmode $(INFILE).tex 2>&1 > /dev/null
	@echo -en "2/3 ${GREEN}OK${NC} "
	@pdflatex -synctex=1 -interaction=nonstopmode $(INFILE).tex 2>&1 > /dev/null
	@echo -e "3/3 ${GREEN}OK${NC}\n${ORANGE}$(INFILE).pdf${NC} generado exitosamente."

latex2pdf_light:
	@echo -n "Cambiando a esquema de color claro: "
	@sed -i '/\\newif\\ifdark\\/s/darktrue/darkfalse/' $(INFILE).tex
	@echo -en "${GREEN}OK${NC}\nGenerando PDF a partir de ${ORANGE}$(INFILE).tex${NC}: "
	@pdflatex -synctex=1 -interaction=nonstopmode $(INFILE).tex 2>&1 > /dev/null
	@echo -en "1/3 ${GREEN}OK${NC} "
	@pdflatex -synctex=1 -interaction=nonstopmode $(INFILE).tex 2>&1 > /dev/null
	@echo -en "2/3 ${GREEN}OK${NC} "
	@pdflatex -synctex=1 -interaction=nonstopmode $(INFILE).tex 2>&1 > /dev/null
	@mv $(INFILE).pdf $(INFILE)-print.pdf
	@echo -e "3/3 ${GREEN}OK${NC}\n${ORANGE}$(INFILE)-print.pdf${NC} generado exitosamente."

html: html_folders html_prepare html_convert html_tidy html_fix_classnames html_custom html_clean html_ok

html_folders:
	@mkdir -p build/configuración/style
	@cp -r configuración/style/* build
	@cp configuración/*.tex build/configuración/
	@cp -r imágenes build/
	@cp -r secciones build/

html_prepare:
	@echo -n "Ajustando subtítulo: "
	@sed '/colorsubtitulo/s/{\\textsc{Diseño\ técnico}}/{Diseño\ técnico}/' $(INFILE).tex > build/$(OUTFILE).tex
	@echo -en "${GREEN}OK${NC}\nAjustando nivel de TOC a ${ORANGE}$(HTML_TOC_LEVEL)${NC} para el html: "
	@sed -i '/\\setcounter/s/{tocdepth}{*.}/{tocdepth}{$(HTML_TOC_LEVEL)}/' build/configuración/estilos.tex
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
	@sed -i "/<h3 class='likesectionHead'>/i \ \ \ \ <input type=\"checkbox\" id=\"showtoc\" checked><div class=\"tocbutton\"></div>" build/export/$(OUTFILE).html
	@echo -en "${GREEN}OK${NC}\nAjustando fracción: "
	@sed -i -r "s/Estudio <span class='(.+?)'>6<\/span><span class='(.+?)'>\/<\/span><span class='(.+?)'>8<\/span>/Estudio 6\/8/" build/export/$(OUTFILE).html
	@echo -en "${GREEN}Ok${NC}\nAgregando espacios a figuras: "
	@sed -i '/<span class='\''id'\''>Figura/s/<\/span>/ <\/span>/' build/export/$(OUTFILE).html
	@sed -i 's/Figura~/Figura /' build/export/$(OUTFILE).html
	@echo -en "${GREEN}OK${NC}\nAgregando fondo: "
	@cp imágenes/fondo.jpg build/export/imágenes/
	@echo -en "${GREEN}OK${NC}\nAgregando íconos: "
	@cp imágenes/icon.svg build/export/imágenes/
	@cp imágenes/flecha.svg build/export/imágenes/
	@sed -i '/\/head/i \ \ \ \ <link rel="icon" href="imágenes\/icon.svg">' build/export/$(OUTFILE).html
	@echo -e "${GREEN}OK${NC}"

html_clean:
	@echo -en "Limpiando archivos de compilación: "
	@cd build && \
	rm -rf configuración imágenes secciones
	@rm build/custom.conf build/tidy.conf build/$(OUTFILE).tex
	@rm build/$(OUTFILE).*
	@mv build/export/* build/
	@rm -r build/export
	@rm -rf docs && mv build docs
	@echo -e "${GREEN}OK${NC}\n.................................................."

html_ok:
	@echo -en "HTML generado exitosamente.\nRevisar en:${ORANGE} file://"
	@echo -n '$(PWD)' | sed -e 's/ñ/%C3%B1/' -e 's/ /%20/' -e 's/é/%C3%A9/'
	@echo -e "/docs/index.html${NC}"
	@echo "Usar 'make sync' para subir a GITHUB."

sync:
	@echo "Sincronizando GITHUB con la última versión de la documentación..."
	@git add .
	@git status
	@echo -e "..................................................\nSubiendo el commit:"
	@git commit -m "Auto uploaded v$(VERSION)"
	@git push
	@echo -e "..................................................\nSincronización exitosa."
	@echo -e "Version web en: ${ORANGE}https://polirritmico.github.io/Bakumapu-docs/${NC}"

reset:
	@rm -rf build
	@mkdir -p temp
	@mv $(INFILE).tex temp/
	@mv $(INFILE).pdf temp/
	-@mv $(INFILE).synctex.gz temp/
	-@rm $(INFILE).*
	@mv temp/* ./
	@rm -r temp
	@rm -r docs

# @: Evita mostrar la llamada del comando en la salida.
# -@: Ignora los comandos que retornan non-successful status.
