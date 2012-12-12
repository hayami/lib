DOTFILES= $(shell for x in .??*; do [ "$$x" != ".git" ] && echo "$$x"; done)
DOTDIR	= $(shell pwd | sed -e "s:^$$HOME/::")
PRIVATE	= $(HOME)/private/dot

commit:
	git commit -a

relink:
	@for f in $(DOTFILES); do \
	    if [ -L $(HOME)/$$f ]; then rm $(HOME)/$$f || return 1; fi; \
	    ln -s $(DOTDIR)/$$f $(HOME) || return 1; \
	    find $(HOME)/$$f -printf '%p -> %l\n'; \
	done
	@[ ! -d $(PRIVATE) ] || $(MAKE) --no-print-directory -C $(PRIVATE) $@
