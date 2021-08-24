SHELL = /bin/sh
# Actualizar con cada cambio
VERSION = 0.0.1

# In/Out target names
INFILE = main
OUTFILE = index

# Define some variables
LATEX=latex
PDFLATEX=pdflatex

# The default targets
#all: latex2html
default:
	@echo -n "Ajustando la versión: "
	@sed -i '/\\newcommand{\\docversion}/s/{\\docversion}{\+.\+.\+}/{\\docversion}{$(VERSION)}/' $(INFILE).tex
	@echo "OK."
	@echo "Utilice 'make html', 'make clean', 'make sync' o 'make all'."

all: clean html sync

html:
	@echo "Generando 'docs/$(OUTFILE).html' a partir de '$(INFILE).tex'"
	@mkdir -p build/configuración/style
	@cp -r configuración/style/* build
	@cp configuración/*.tex build/configuración/
	@cp -r imágenes build/
	@cp -r secciones build/
	@echo -n "Ajustando versión y subtítulo: "
	@sed -i '/\\newcommand{\\docversion}/s/{\\docversion}{\+.\+.\+}/{\\docversion}{$(VERSION)}/' $(INFILE).tex
	@sed '/colorsubtitulo/s/{\\textsc{Diseño\ técnico}}/{Diseño\ técnico}/' <$(INFILE).tex >build/$(OUTFILE).tex

	@echo -e "OK\nIniciando conversión:\n.................................................."
	@cd build && \
	make4ht -c custom.conf -d export/ $(OUTFILE).tex "fn-in"

	@echo -e "OK\nLimpiando html con tidy:"
	@-cd build && \
	tidy -config tidy.conf export/$(OUTFILE).html > export/temp-$(OUTFILE).html
	@mv build/export/temp-$(OUTFILE).html build/export/$(OUTFILE).html

	@echo -en "Corrigiendo espacios a comandos con signos '\$$': "
	@sed -i 's/$$<\/span><\/span>/$$ <\/span><\/span>/' build/export/$(OUTFILE).html
	@echo -en "OK\nAjustando espacios: "
	@sed -i '/<span/s/ / /g' build/export/$(OUTFILE).html
	@echo -en "OK\nAjustando links a target='_blank': "
	@sed -i -r "s/<a href='http([^>]*)'>/<a href='http\1' target='_blank'>/" build/export/$(OUTFILE).html
#	@echo -en "OK\nQuitando puntos a referencias: "
#	@sed -i '/<a /s/.<!-- tex4ht:/<!-- tex4ht:/g' build/export/$(OUTFILE).html
	@echo -en "Ok\nAgregando espacios a figuras: "
	@sed -i '/<span class='\''id'\''>Figura/s/<\/span>/ <\/span>/' build/export/$(OUTFILE).html

	@echo -en "OK\nLimpiando archivos de compilación: "
	@cd build && \
	rm -rf configuración imágenes secciones
	@rm build/custom.conf build/tidy.conf build/$(OUTFILE).tex
	@rm build/$(OUTFILE).*
	@mv build/export/* build/
	@rm -r build/export
	@rm -rf docs && mv build docs
	@echo -e "OK\n.................................................."
	@echo -e "HTML generado exitosamente."
	@echo "Revisar en: file:///home/eduardo/Documentos/Bakumapu/Dise%C3%B1o%20t%C3%A9cnico/docs/index.html"
	@echo "Usar 'make sync' para subir a GITHUB."
	\

clean:
	@mkdir -p temp
	@mv $(INFILE).tex temp/
	@mv $(INFILE).pdf temp/
	-@mv $(INFILE).synctex.gz temp/
	-@rm $(INFILE).*
	@mv temp/* ./
	@rm -r temp

clear:
	@rm -rf build
	@mkdir -p temp
	@mv $(INFILE).tex temp/
	@mv $(INFILE).pdf temp/
	-@mv $(INFILE).synctex.gz temp/
	-@rm $(INFILE).*
	@mv temp/* ./
	@rm -r temp
	@rm -r docs

sync:
	@echo "Sincronizando GITHUB con la última versión de la documentación..."
	@git add .
	@git status
	@echo -e "..................................................\nSubiendo el commit:"
	@git commit -m "Auto uploaded v$(VERSION)"
	@git push
	@echo -e "..................................................\nSincronización exitosa."
	@echo "Version web en: https://polirritmico.github.io/Bakumapu-docs/"
