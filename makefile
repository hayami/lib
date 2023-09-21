# vim: noet sw=8 sts=8

# Initial setup steps in vanilla home directory follows:
# 	cd ~
# 	git clone https://github.com/hayami/dot.git
# 	cd dot
# 	make install
# 	(umask 077 && mkdir -p ../private/dot)
# 	(umask 077 && cp -i makefile-private-template ../private/dot/makefile)
# 	make relink

PRIVATE	:= $(HOME)/private/dot
USRLOCAL:= usrlocal
EXCLUDE	:= .|..|.git|.gitignore|bin|sys|makefile*
LINKS	:= ${shell for i in .* *; do case $$i in \
	   $(EXCLUDE));; *) echo $$i;; esac; done}
DOTDIR	:= $(shell pwd | sed -e "s|^$$HOME/||")
PRIVDOT	:= $(shell echo $(PRIVATE) | sed -e "s|^$$HOME/||")
NODE	:= $(shell node=$$(uname -n); echo $${node%%[0-9.]*})

ifeq ($(NODE),www)
USRLOCAL:= syslocal
ifneq ($(DOTDIR),$(PRIVDOT))
LINKS	:= ${shell for i in \
	   .less* .termcap .tmux.conf .vimrc .zsh* \
	   ; do [ -e "$$i" ] || continue; case $$i in \
	   $(EXCLUDE));; *) echo $$i;; esac; done}
endif
endif

MAKEFLAGS += --no-print-directory

.NOTPARALLEL:

# ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
.PHONY:	default	usage help

default: usage

usage help:
	@printf "usage: make [options]\n"
	@printf "options are:\n"
	@printf "	usage (or help)\n"
	@printf "	relink\n"
	@printf "\n"
	@printf "Initial setup steps in vanilla home directory follows:\n"
	@printf "	cd ~\n"
	@printf "	git clone https://github.com/hayami/dot.git\n"
	@printf "	cd dot\n"
	@printf "	make install\n"
	@printf "	(umask 077 && mkdir -p ../private/dot)\n"
	@printf "	(umask 077 "
	@printf "&& cp -i makefile-private-template ../private/dot/makefile)\n"
	@printf "	make relink\n"

# ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
.PHONY: relink
.PHONY: relink-common relink-public relink-private

relink:
	[ ! -n "$(PRIVATE)" ] || $(MAKE) $@-public
	[ ! -z "$(PRIVATE)" ] || $(MAKE) $@-private
	[ ! -d "$(PRIVATE)" ] || $(MAKE) -C "$(PRIVATE)" $@-private

relink-common:
	@for f in $(LINKS); do \
	    if [ -L $(HOME)/$$f ]; then rm $(HOME)/$$f || exit 1; fi; \
	    if [ -e $(HOME)/$$f ]; then ls -ld $(HOME)/$$f; exit 1; fi; \
	    ln -s $(DOTDIR)/$$f $(HOME) || exit 1; \
	    find $(HOME)/$$f -printf '\033[32m%p -> %l\033[0m\n' \
	    || ls -ld $(HOME)/$$f; \
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
	[ ! -d tpl.bin      ] || install -m 0755 tpl.bin/* $(HOME)/bin/
	[ ! -d "$(PRIVATE)" ] || $(MAKE) -C "$(PRIVATE)" $@

sys-install:
	[ -n "$(PRIVATE)" ]
	install -d -m 0755 $(HOME)/sys
	install -d -m 0755 $(HOME)/sys/$(USRLOCAL)
	install -d -m 0755 $(HOME)/sys/backup
	install -d -m 0755 $(HOME)/sys/backup/orig
	install -d -m 0755 $(HOME)/sys/backup/new
	$(MAKE) sys-update

sys-update:
	[ -n "$(PRIVATE)" ]
	install -m 0644 tpl.sys/usrlocal/Makefile $(HOME)/sys/$(USRLOCAL)/
	install -m 0644 tpl.sys/backup/Makefile $(HOME)/sys/backup/
	install -m 0755 tpl.sys/backup/*.sh $(HOME)/sys/backup/

PRIVATE_DIRS := .ssh .gnupg

private-dirs:
	@dir="$(PRIVATE)"; \
	while [ -n "$$dir" -a "$$dir" != "/" -a "$$dir" != "$(HOME)" ]; do \
	    cmd="install -d -m 0700 $$dir"; echo $$cmd; $$cmd || exit 1; \
	    dir=`dirname $$dir`; \
	done
	@for d in $(PRIVATE_DIRS); do \
	    if [ -z "$(PRIVATE)" ]; then \
	         cmd="install -d -m 0700 $$d"; \
	    else \
	         cmd="install -d -m 0700 $(PRIVATE)/$$d"; \
	    fi; \
	    echo $$cmd; $$cmd || exit 1; \
	done

# ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- -----

# EOF
