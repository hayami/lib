DOTFILES= $(shell for x in .??*; do [ "$$x" != ".git" ] && echo "$$x"; done)
DOTDIR	= $(shell pwd | sed -e "s:^$$HOME/::")
RELHOME	= $(shell echo $(DOTDIR) | sed -e 's:[^/]\+:..:g')

relink:
	for f in $(DOTFILES); do \
	    if [ -L $(RELHOME)/$$f ]; then rm $(RELHOME)/$$f || return 1; fi; \
	    ln -s $(DOTDIR)/$$f $(RELHOME) || return 1; \
	done
