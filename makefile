# vim: noet sw=8 sts=8

NODE	:= $(shell uname -n | sed -e 's/[\.0-9].*//')

EXCLUDE	:= .|..|.git|.gitignore|bin|sys|makefile*
LINKS	:= ${shell for i in .* *; do case $$i in \
	   $(EXCLUDE));; *) echo $$i;; esac; done}

ifeq ($(NODE),www)
LINKS	:= ${shell for i in .less* .vimrc .zsh*; do case $$i in \
	   $(EXCLUDE));; *) echo $$i;; esac; done}
endif

DOTDIR	:= $(shell pwd | sed -e "s:^$$HOME/::")
PRIVATE	:= $(HOME)/private/dot

MAKEFLAGS += --no-print-directory

.NOTPARALLEL:

# ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
.PHONY:	default
.PHONY:	commit+push commit push

default: commit+push

commit+push: commit push

commit:
	git commit -a

push:
	git push origin master

# ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
.PHONY: relink
.PHONY: relink-common relink-public relink-private

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

ifeq ($(XMODMAP),)
ifeq ($(NODE),albion)
XMODMAP	:= xmodmap.pointer23
endif
endif

relink-xfce4-xinitrc:
	cd $(HOME)/.config/xfce4
	cd $(HOME)/.config/xfce4; [ ! -L xinitrc ] || rm xinitrc
	cd $(HOME)/.config/xfce4; [ ! -e xinitrc ]
	ln -s ../../$(DOTDIR)/.xmisc/xfce4-xinitrc $(HOME)/.config/xfce4/xinitrc

relink-public: relink-common
	[ ! -d $(HOME)/.config/xfce4 ] || $(MAKE) relink-xfce4-xinitrc
	:
ifneq ($(XMODMAP),)
	[ -e .xmisc/$(XMODMAP) ]
	[ ! -L $(HOME)/.Xmodmap ] || rm $(HOME)/.Xmodmap
	[ ! -e $(HOME)/.Xmodmap ]
	ln -s $(DOTDIR)/.xmisc/$(XMODMAP) $(HOME)/.Xmodmap
endif

# ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
.PHONY: install update
.PHONY: bin-install bin-update sys-install sys-update private-dirs

install: bin-install sys-install private-dirs

update:	bin-update sys-update

bin-install:
	[ -n "$(PRIVATE)" ]
	install -d -m 0755 $(HOME)/bin
	$(MAKE) bin-update

bin-update:
	[ ! -d bin ] || install -m 0755 bin/* $(HOME)/bin/
	[ ! -d "$(PRIVATE)" ] || $(MAKE) -C "$(PRIVATE)" $@

sys-install:
	[ -n "$(PRIVATE)" ]
	install -d -m 0755 $(HOME)/sys
	install -d -m 0755 $(HOME)/sys/usrlocal
	install -d -m 0755 $(HOME)/sys/backup
	install -d -m 0755 $(HOME)/sys/backup/orig
	install -d -m 0755 $(HOME)/sys/backup/new
	$(MAKE) sys-update

sys-update:
	[ -n "$(PRIVATE)" ]
	install -m 0644 sys/usrlocal/Makefile $(HOME)/sys/usrlocal/
	install -m 0644 sys/backup/Makefile $(HOME)/sys/backup/
	install -m 0755 sys/backup/*.sh $(HOME)/sys/backup/

PRIVATE_DIRS := .ssh .gnupg

private-dirs:
	@dir="$(PRIVATE)"; \
	while [ -n "$$dir" -a "$$dir" != "/" -a "$$dir" != "$(HOME)" ]; do \
	    cmd="install -d -m 0700 $$dir"; echo $$cmd; $$cmd || return 1; \
	    dir=`dirname $$dir`; \
	done
	@for d in $(PRIVATE_DIRS); do \
	    if [ -z "$(PRIVATE)" ]; then \
	         cmd="install -d -m 0700 $$d"; \
	    else \
	         cmd="install -d -m 0700 $(PRIVATE)/$$d"; \
	    fi; \
	    echo $$cmd; $$cmd || return 1; \
	done
	 
# ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- -----

# EOF
