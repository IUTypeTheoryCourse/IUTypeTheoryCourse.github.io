#!/bin/sh

# this should be better lmao

rm -rf docs/*
scribble --htmls --dest ./docs --redirect-main "https://docs.racket-lang.org" index.scrbl
mv docs/index/* docs/
