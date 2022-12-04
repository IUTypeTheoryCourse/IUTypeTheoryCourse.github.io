.PHONY: all clean sync serve help build docs-server



.racodeps: info.rkt
	raco pkg install --skip-installed --batch --auto
	touch $@

build: build/index.html

build/cpsc411.sxref:
	mkdir -p build
	scribble --dest ./build --dest-name cpsc411 --htmls --info-out build/cpsc411.sxref +m --redirect-main "https://docs.racket-lang.com" ++style assignment/custom.css `racket -e "(void (write-string (path->string (collection-file-path \"cpsc411.scrbl\" \"cpsc411\"))))"`

clean:
	echo "You should manually run `git clean -ixd` in build."
	rm -rf compiled/
