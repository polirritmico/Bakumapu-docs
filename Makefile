SHELL = /bin/sh
VERS = 0.0.1

#OTHER = README CHANGES
INFILE = main
OUTFILE = Diseño_técnico

# Define some variables
LATEX=latex
PDFLATEX=pdflatex

# The default targets
#all: latex2html
default:
	@echo "Utilice 'make html' o 'make clean'."

html:
	@echo "Generando 'html/$(OUTFILE).html' a partir de '$(INFILE).tex'"
	@mkdir -p build/configuración/style
	@cp -r configuración/style/* build
	@cp configuración/*.tex build/configuración/
	@cp -r imágenes build/
	@cp -r secciones build/
	@sed '/colorsubtitulo/s/{\\textsc{Diseño\ técnico.}}/{Diseño\ técnico.}/' <$(INFILE).tex >build/$(OUTFILE).tex
	@cd build && \
	make4ht -c custom.cfg -d export/ $(OUTFILE).tex "fn-in"
	@cd build && \
	rm -rf configuración imágenes secciones
	@rm build/custom.cfg build/$(OUTFILE).tex
	@rm build/$(OUTFILE).*
	@mv build/export/* build/
	@rm -r build/export
	@mv build html

clean:
	@mkdir -p temp
	@mv $(INFILE).tex temp/
	@mv $(INFILE).pdf temp/
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
	@rm -r html
