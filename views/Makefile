
PROGRAM = /usr/bin/sass

OBJS = nav.css overlaid.css style.css
all:  $(OBJS)

nav.css: nav.sass
	$(PROGRAM) --no-cache --sourcemap=none $< $@

overlaid.css: overlaid.sass
	$(PROGRAM) --no-cache --sourcemap=none $< $@

style.css: style.sass
	$(PROGRAM) --no-cache --sourcemap=none $< $@


