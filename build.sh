#!/bin/sh

# this should be better lmao

scribble --htmls --dest ./docs --redirect-main "https://docs.racket-lang.org" index.scrbl
mv docs/index/* docs/
