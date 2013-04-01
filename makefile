# vim: noet sw=8 sts=8
NODE	:= $(shell uname -n | sed -e 's/[\.0-9].*//')
LINKS	:= ${shell for i in .* *; do case $$i in \
	   .|..|.git|.gitignore|makefile);; \
	   *) echo $$i;; esac; done}
DOTDIR	:= $(shell pwd | sed -e "s:^$$HOME/::")
PRIVATE	:= $(HOME)/private/dot

MAKEFLAGS += --no-print-directory

.PHONY:	default commit+push commit push
.PHONY: relink relink-commonn relink-public relink-private
.NOTPARALLEL:

default: commit+push

commit+push: commit push

commit:
	git commit -a

push:
	git push

relink:
	[ ! -n "$(PRIVATE)" ] || $(MAKE) $@-public
	[ ! -z "$(PRIVATE)" ] || $(MAKE) $@-private
	[ ! -d "$(PRIVATE)" ] || $(MAKE) -C "$(PRIVATE)" $@-private

relink-common:
	@for f in $(LINKS); do \
	    if [ -L $(HOME)/$$f ]; then rm $(HOME)/$$f || return 1; fi; \
	    if [ -e $(HOME)/$$f ]; then ls -ld $(HOME)/$$f; return 1; fi; \
	    ln -s $(DOTDIR)/$$f $(HOME) || return 1; \
	    find $(HOME)/$$f -printf '%p -> %l\n'; \
	done
	[ ! -f .netrc       ] || chmod 0600 .netrc
	[ ! -f .procmailrc  ] || chmod 0600 .procmailrc
	[ ! -f .fetchmailrc ] || chmod 0600 .fetchmailrc

relink-public: relink-common
ifeq ($(NODE),tako)
	cd $(HOME)/.config/xfce4
	cd $(HOME)/.config/xfce4; [ ! -L xinitrc ] || rm xinitrc
	cd $(HOME)/.config/xfce4; [ ! -e xinitrc ]
	ln -s ../../$(DOTDIR)/.xmisc/xfce4-xinitrc $(HOME)/.config/xfce4/xinitrc
	:
	[ ! -L $(HOME)/.Xmodmap ] || rm $(HOME)/.Xmodmap
	[ ! -e $(HOME)/.Xmodmap ]
	ln -s $(DOTDIR)/.xmisc/xmodmap.ArcKeyboard $(HOME)/.Xmodmap
endif

# EOF
