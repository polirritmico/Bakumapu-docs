SHELL = /bin/sh
VERSION = 0.0.1

#OTHER = README CHANGES
INFILE = main
OUTFILE = index

# Define some variables
LATEX=latex
PDFLATEX=pdflatex

# The default targets
#all: latex2html
default:
	@echo "Utilice 'make html', 'make clean' o 'make sync'."

html:
	@echo "Generando 'docs/$(OUTFILE).html' a partir de '$(INFILE).tex'"
	@mkdir -p build/configuración/style
	@cp -r configuración/style/* build
	@cp configuración/*.tex build/configuración/
	@cp -r imágenes build/
	@cp -r secciones build/
	@echo -n "Ajustando versión y subtítulo: "
	@sed '/\\newcommand{\\docversion}/s/{\\docversion}{\+.\+.\+}/{\\docversion}{$(VERSION)}/' <$(INFILE).tex >build/$(OUTFILE).tex
	@sed -i '/colorsubtitulo/s/{\\textsc{Diseño\ técnico.}}/{Diseño\ técnico.}/' build/$(OUTFILE).tex
	@echo -e "OK\nIniciando conversión:\n.................................................."
	@cd build && \
	make4ht -c custom.cfg -d export/ $(OUTFILE).tex "fn-in"
	@cd build && \
	rm -rf configuración imágenes secciones
	@rm build/custom.cfg build/$(OUTFILE).tex
	@rm build/$(OUTFILE).*
	@mv build/export/* build/
	@rm -r build/export
	@rm -r docs && mv build docs
	@echo -en "Corrigiendo espacios a comandos con signos '\$$': "
	@sed -i 's/$$<\/span><\/span>/$$ <\/span><\/span>/' docs/$(OUTFILE).html
	@echo -e "OK\n.................................................."
	@echo -e "HTML generado exitosamente.\nUsar 'make sync' para subir a GITHUB."

clean:
	@mkdir -p temp
	@mv $(INFILE).tex temp/
	@mv $(INFILE).pdf temp/
	-@mv $(INFILE).synctex.gz temp/
	-@rm $(INFILE).*
	@mv temp/* ./
	@rm -r temp

clear:
	@mkdir -p temp
	@mv $(INFILE).tex temp/
	@mv $(INFILE).pdf temp/
	-@rm $(INFILE).*
	@mv temp/* ./
	@rm -r temp
	@rm -r docs

sync:
	@echo "Sincronizando GITHUB con la última versión de la documentación..."
	@git add .
	git status
	@git commit -m "Uploaded repo by Makefile"
	@git push
	@echo "Version web en: https://polirritmico.github.io/Bakumapu-docs/"
