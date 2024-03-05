SUDO	:= $(shell [ "$$(id -u)" != "0" -a ! -d "$$HOME/sys/local" ] \
	   && which sudo > /dev/null 2>&1 && echo -n "sudo")
PREFIX	:= $(shell [ -d "$$HOME/sys/local" ] \
	   && echo -n "$$HOME/sys/local" || echo -n "/usr/local")
TMPDIR	= .tmp
RKIVDIR	= /mnt/backup/tmp

filecheck check: tmpdir filelist
	for f in $$(find * -maxdepth 0 -type f -print); do \
	    sed -n -e '/^-- INSTALLED FILES --$$/,$$p' $$f | tail -n +2; \
	done | sed -e 's/ -> .*//' | sort > $(TMPDIR)/ulist
	uniq $(TMPDIR)/ulist > $(TMPDIR)/clist
	uniq -d $(TMPDIR)/ulist > $(TMPDIR)/dlist
	comm     $(TMPDIR)/flist $(TMPDIR)/clist > $(TMPDIR)/comm
	comm -23 $(TMPDIR)/flist $(TMPDIR)/clist > $(TMPDIR)/comm1
	comm -13 $(TMPDIR)/flist $(TMPDIR)/clist > $(TMPDIR)/comm2
	comm -12 $(TMPDIR)/flist $(TMPDIR)/clist > $(TMPDIR)/comm3
	@if [ -s $(TMPDIR)/dlist ]; then \
	    echo; \
	    (	echo -n "*** Following files are registerd in duplicate."; \
		echo; cat $(TMPDIR)/dlist; \
	    ) 1>&2; \
	fi
	@if [ -s $(TMPDIR)/comm1 ]; then \
	    echo; \
	    (	echo -n "*** Following files are illegally exist"; \
		echo -n " or not registerd in this directory."; \
		echo; cat $(TMPDIR)/comm1; \
	    ) 1>&2; \
	fi
	@if [ -s $(TMPDIR)/comm2 ]; then \
	    echo; \
	    (	echo -n "*** Following files are registerd"; \
		echo -n " in this directory, but not exist."; \
		echo; cat $(TMPDIR)/comm2; \
	    ) 1>&2; \
	fi

filelist: tmpdir
	regexp=$$(while read re; do			\
		    echo -n "$$or$$re";			\
		    or='|';				\
		done < EXCLUDES);			\
	(cd $(PREFIX) && $(SUDO) find . -xdev -print)	\
	| sed -e 's;^\.;$(PREFIX);'			\
	| egrep -v "^($$regexp)$$"			\
	| sort -u					\
	| sed -e 's|^'"$$HOME"'/|$$HOME/|'		\
	> $(TMPDIR)/flist
	@cmd="cp $(TMPDIR)/flist $(TMPDIR)/filelist-$$(date +%T)"; \
	echo $$cmd; eval $$cmd

tmpdir:
	test -d $(TMPDIR) || mkdir $(TMPDIR)

clean:
	rm -rf $(TMPDIR)

rkiv-all: clean
	touch $(RKIVDIR)/$$(date '+%Y-%m-%d'),usrlocal.tar.gz
	LANG=C $(SUDO) tar \
	--gzip \
	--create \
	--sparse \
	--numeric-owner \
	--atime-preserve \
	--one-file-system \
	--file $(RKIVDIR)/$$(date '+%Y-%m-%d'),usrlocal.tar.gz \
	--directory $(PREFIX) .

rkiv-pkg: tmpdir
	[ -f "$(PKG)" ] || { echo "usage: make $@ PKG=foo-1.2.3" 1>&2; exit 1; }
	rm -f $(TMPDIR)/$(PKG)-*
	sed -n -e '/^-- INSTALLED FILES --$$/,$$p' $(PKG) | tail -n +2 \
	| sed -e 's/ -> .*//' -e 's|^[$$]HOME/|'"$$HOME"'/|' \
	| sort -u | tee $(TMPDIR)/$(PKG)-list \
	| while read f; do [ -L "$$f" -o ! -d "$$f" ] || echo "//$$f"; done \
	>  $(TMPDIR)/$(PKG)-dirs2
	while read d2; do fgrep "$$d2/" $(TMPDIR)/$(PKG)-dirs2; done \
	< $(TMPDIR)/$(PKG)-dirs2 | sort -u > $(TMPDIR)/$(PKG)-dirs2c
	comm -23 $(TMPDIR)/$(PKG)-dirs2 $(TMPDIR)/$(PKG)-dirs2c \
	> $(TMPDIR)/$(PKG)-dirs2u
	(   sed -e 's#^#//#' $(TMPDIR)/$(PKG)-list \
	    | fgrep -v -f $(TMPDIR)/$(PKG)-dirs2u; \
	    cat $(TMPDIR)/$(PKG)-dirs2u \
	) | sed -e 's#^//##' | sort -u > $(TMPDIR)/$(PKG)-tarlist
	[ ! -f "$(PKG)-rkiv.tar.gz" ]
	touch "$(PKG)-rkiv.tar.gz"
	LANG=C $(SUDO) tar --numeric-owner --atime-preserve --one-file-system \
	 --sparse -T $(TMPDIR)/$(PKG)-tarlist -czf $(PKG)-rkiv.tar.gz

remove-pkg: tmpdir
	[ -f "$(PKG)" ] || { echo "usage: make $@ PKG=foo-1.2.3" 1>&2; exit 1; }
	sed -n -e '/^-- INSTALLED FILES --$$/,$$p' $(PKG) | tail -n +2 \
	| sed -e 's/ -> .*//' -e 's|^[$$]HOME/|'"$$HOME"'/|' | sort -ru \
	| while read f; do			\
	    if [ -L "$$f" ]; then		\
		echo "rm	\"$$f\"";	\
	    elif [ -d "$$f" ]; then		\
		echo "rmdir	\"$$f\"";	\
	    else				\
		echo "rm	\"$$f\"";	\
	    fi;					\
	done > $(TMPDIR)/$(PKG)-remove.sh
	@echo
	@echo "Run /bin/sh -xe $(TMPDIR)/$(PKG)-remove.sh to remove \"$(PKG)\"."

# EOF
