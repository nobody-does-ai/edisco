all:


TESSDATA_PREFIX:=/usr/local/share/tessdata_best
export TESSDATA_PREFIX;

src:=$(wildcard src/*.pdf)
png:=$(src:.pdf=.png)

src/pdf:=$(wildcard src/*.pdf)
pgs/pdf:=$(patsubst src/%.pdf,pgs/%-pdf.pgs,$(src/pdf))

all: $(pgs/pdf)

$(inv): $(tsv)
	./bin/tsv-lines

pgs/%-pdf.pgs: src/%.pdf
	./bin/ppdf-split $<
	touch $@

pgs/%.tsv: pgs/%.png
	mkdir -p tsv
	tesseract -l eng $< $(<:.png=) tsv

ifeq (x,)
png:=$(patsubst pgs/%.pdf,pgs/%.pdf.png,$(pdf))
tsv:=$(patsubst pgs/%.png,tsv/%.tsv,$(png))
inv:=inv/invest.json
inv: $(inv)
png: $(png)
tsv: $(tsv)

all: tsv inv
endif
