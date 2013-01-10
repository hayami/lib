# vim: noet sw=8 sts=8
LINKS	:= ${shell for i in .* *; do case $$i in \
	   .|..|.git|.gitignore|makefile);; \
	   *) echo $$i;; esac; done}
DOTDIR	:= $(shell pwd | sed -e "s:^$$HOME/::")
PRIVATE	:= $(HOME)/private/dot

MAKEFLAGS += --no-print-directory

.PHONY:	default commit+push commit push relink
.NOTPARALLEL:

default: commit+push

commit+push: commit push

commit:
	git commit -a

push:
	git push

relink:
	@for f in $(LINKS); do \
	    if [ -L $(HOME)/$$f ]; then rm $(HOME)/$$f || return 1; fi; \
	    if [ -e $(HOME)/$$f ]; then ls -ld $(HOME)/$$f; return 1; fi; \
	    ln -s $(DOTDIR)/$$f $(HOME) || return 1; \
	    find $(HOME)/$$f -printf '%p -> %l\n'; \
	done
	[ ! -f .netrc      ] || chmod 0600 .netrc
	[ ! -f .procmailrc ] || chmod 0600 .procmailrc
	[ -z "$(PRIVATE)" ] || $(MAKE) -C "$(PRIVATE)" $@-private

# EOF
