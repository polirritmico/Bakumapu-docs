SHELL = /bin/sh
# Actualizar con cada cambio
VERSION = 0.0.6

# Define variables
LATEX=latex
PDFLATEX=pdflatex
HTML_TOC_LEVEL=2

# In/Out target names
INFILE = main
OUTFILE = index

default:
	@echo "Utilice `make all`, `make pdf`, `make version`, `make sync` o `make clean`."

all: pdf clean html sync

pdf: version latex2pdf_light latex2pdf

version:
	@echo -n "Ajustando la versión: "
	@sed -i '/\\newcommand{\\docversion}/s/{\\docversion}{\+.\+.\+}/{\\docversion}{$(VERSION)}/' $(INFILE).tex
	@echo "OK"

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
	@echo -en "OK\nGenerando PDF a partir de $(INFILE).tex: "
	@pdflatex -synctex=1 -interaction=nonstopmode $(INFILE).tex 2>&1 > /dev/null
	@echo -n "1/3 OK "
	@pdflatex -synctex=1 -interaction=nonstopmode $(INFILE).tex 2>&1 > /dev/null
	@echo -n "2/3 OK "
	@pdflatex -synctex=1 -interaction=nonstopmode $(INFILE).tex 2>&1 > /dev/null
	@echo -e "3/3 OK\n$(INFILE).pdf generado exitosamente."

latex2pdf_light:
	@echo -n "Cambiando a esquema de color claro: "
	@sed -i '/\\newif\\ifdark\\/s/darktrue/darkfalse/' $(INFILE).tex
	@echo -en "OK\nGenerando PDF a partir de $(INFILE).tex: "
	@pdflatex -synctex=1 -interaction=nonstopmode $(INFILE).tex 2>&1 > /dev/null
	@echo -n "1/3 OK "
	@pdflatex -synctex=1 -interaction=nonstopmode $(INFILE).tex 2>&1 > /dev/null
	@echo -n "2/3 OK "
	@pdflatex -synctex=1 -interaction=nonstopmode $(INFILE).tex 2>&1 > /dev/null
	@mv $(INFILE).pdf $(INFILE)-print.pdf
	@echo -e "3/3 OK\n$(INFILE)-print.pdf generado exitosamente."

html: html_folders html_prepare html_convert html_tidy html_custom html_clean html_ok

html_folders:
	@mkdir -p build/configuración/style
	@cp -r configuración/style/* build
	@cp configuración/*.tex build/configuración/
	@cp -r imágenes build/
	@cp -r secciones build/

html_prepare:
	@echo -n "Ajustando subtítulo: "
	@sed '/colorsubtitulo/s/{\\textsc{Diseño\ técnico}}/{Diseño\ técnico}/' <$(INFILE).tex >build/$(OUTFILE).tex
	@echo -en "OK\nAjustando nivel de TOC a $(HTML_TOC_LEVEL) para el html: "
	@sed -i '/\\setcounter/s/{tocdepth}{*.}/{tocdepth}{$(HTML_TOC_LEVEL)}/' build/configuración/estilos.tex
	@echo "OK"

html_convert:
	@echo "Generando 'docs/$(OUTFILE).html' a partir de '$(INFILE).tex'"
	@echo -e "Iniciando conversión:\n.................................................."
	@cd build && \
	make4ht -c custom.conf -d export/ $(OUTFILE).tex "fn-in"
	@echo "Conversión OK"

html_tidy:
	@echo -n "Limpiando html con tidy: "
	@-cd build && \
	tidy -config tidy.conf export/$(OUTFILE).html > export/temp-$(OUTFILE).html
	@mv build/export/temp-$(OUTFILE).html build/export/$(OUTFILE).html
	@echo "OK"

html_custom:
	@echo -n "Ajustando título del HTML: "
	@sed -i 's/<title><\/title>/<title>Bakumapu v$(VERSION)<\/title>/' build/export/$(OUTFILE).html
	@echo -en "Corrigiendo espacios a comandos con signos '\$$': "
	@sed -i 's/$$<\/span><\/span>/$$ <\/span><\/span>/' build/export/$(OUTFILE).html
	@echo -en "OK\nAjustando espacios: "
	@sed -i '/<span/s/ / /g' build/export/$(OUTFILE).html
	@echo -en "OK\nAjustando links a target='_blank': "
	@sed -i -r "s/<a href='http([^>]*)'>/<a href='http\1' target='_blank'>/" build/export/$(OUTFILE).html
	@echo -en "Ok\nAgregando espacios a figuras: "
	@sed -i '/<span class='\''id'\''>Figura/s/<\/span>/ <\/span>/' build/export/$(OUTFILE).html
	@sed -i 's/Figura~/Figura /' build/export/$(OUTFILE).html
	@echo -en "OK\nAgregando fondo: "
	@cp imágenes/fondo.jpg build/export/imágenes/
	@echo -en "OK\nAgregando favicon: "
	@cp imágenes/icon.svg build/export/imágenes/
	@sed -i '/\/head/i \ \ \ \ <link rel="icon" href="imágenes\/icon.svg">' build/export/$(OUTFILE).html
	@echo "OK"

html_clean:
	@echo -en "Limpiando archivos de compilación: "
	@cd build && \
	rm -rf configuración imágenes secciones
	@rm build/custom.conf build/tidy.conf build/$(OUTFILE).tex
	@rm build/$(OUTFILE).*
	@mv build/export/* build/
	@rm -r build/export
	@rm -rf docs && mv build docs
	@echo -e "OK\n.................................................."

html_ok:
	@echo -en "HTML generado exitosamente.\nRevisar en: file://"
	@echo -n '$(PWD)' | sed -e 's/ñ/%C3%B1/' -e 's/ /%20/' -e 's/é/%C3%A9/'
	@echo -e "/docs/index.html"
	@echo "Usar 'make sync' para subir a GITHUB."

sync:
	@echo "Sincronizando GITHUB con la última versión de la documentación..."
	@git add .
	@git status
	@echo -e "..................................................\nSubiendo el commit:"
	@git commit -m "Auto uploaded v$(VERSION)"
	@git push
	@echo -e "..................................................\nSincronización exitosa."
	@echo "Version web en: https://polirritmico.github.io/Bakumapu-docs/"

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