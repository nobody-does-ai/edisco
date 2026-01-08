all:


TESSDATA_PREFIX:=/usr/local/share/tessdata_best
export TESSDATA_PREFIX;

pdf:=$(wildcard pgs/*.pdf)
png:=$(patsubst pgs/%.pdf,pgs/%.png,$(pdf))
tsv:=$(patsubst pgs/%.png,tsv/%.pdf.tsv,$(png))
png: $(png)
tsv: $(tsv)

all: tsv

pgs/%.pdf.png: pgs/%.pdf
	pdftoppm -png -r 300 -singlefile $< $<

tsv/%.tsv: pgs/%.png
	mkdir -p tsv
	tesseract -l eng $< $(<:.png=) tsv
	mv $(<:.png=).tsv $@
