# vim: noet sw=8 sts=8
DOTFILES= $(shell for x in .??*; do [ "$$x" != ".git" ] && echo "$$x"; done)
DOTDIR	= $(shell pwd | sed -e "s:^$$HOME/::")
PRIVATE	= $(HOME)/private/dot

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
	@[ ! -d $(PRIVATE) ] || $(MAKE) --no-print-directory -C $(PRIVATE) $@

# EOF
