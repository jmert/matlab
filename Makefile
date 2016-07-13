.PHONY: clean

all:

clean:
	find . -path .git -prune -o -iname '*.mex*' \
		-exec rm -fr {} \;

