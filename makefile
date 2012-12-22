# vim: noet sw=8 sts=8
DOTFILES= $(shell git ls-files .??* | sed -e 's:/.*::' | sort -u)
DOTDIR	= $(shell pwd | sed -e "s:^$$HOME/::")
PRIVATE	= $(HOME)/private/dot

MAKEFLAGS += --no-print-directory
.PHONY:	default commit relink

default: commit

commit:
	git commit -a
	git push

relink:
	@for f in $(DOTFILES); do \
	    if [ -L $(HOME)/$$f ]; then rm $(HOME)/$$f || return 1; fi; \
	    ln -s $(DOTDIR)/$$f $(HOME) || return 1; \
	    find $(HOME)/$$f -printf '%p -> %l\n'; \
	done
	[ ! -f .netrc ] || chmod 600 .netrc
	@[ ! -d $(PRIVATE) ] || $(MAKE) -C $(PRIVATE) $@

# EOF
