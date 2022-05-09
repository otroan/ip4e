SOURCES?=${wildcard *.md}
TEXT=${SOURCES:.md=.txt}

text:	$(TEXT)

%.xml:	%.md
	kramdown-rfc2629 $< >$@.new
	mv $@.new $@

%.txt:	%.xml
	xml2rfc $<