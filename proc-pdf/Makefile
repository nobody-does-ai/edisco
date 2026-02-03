MAKEFLAGS+= -rR
CXX:=g++

all: 
all+=bin/ppdf-pg

tags: bin/* lib/*
	./bin/mk-tags

include /dev/null $(wildcard pages.mk)


all: $(all)
