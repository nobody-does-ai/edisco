MAKEFLAGS+= -rR
CXX:=g++

all: 
all+=bin/ppdf-tsv

tags: bin/* lib/*
	./bin/mk-tags

include /dev/null $(wildcard pages.mk)


all: $(all)
	./bin/ppdf-tsv
