#!/bin/sh

# this should be better lmao

rm -rf docs/*
scribble --htmls --dest ./docs ++xref-in setup/xref load-collections-xref --redirect-main "https://docs.racket-lang.org" index.scrbl
mv docs/index/* docs/
