current	= $(shell dpkg -l xkb-data | while read a b c d e; do \
	          [ "$$b" != "xkb-data" ] || echo "$$c"; done)
dpkgurl	= https://mirrors.kernel.org/ubuntu/pool/main/x/xkeyboard-config/xkb-data_$(current)_all.deb
prefix	= dpkg/xkb-data_$(current)
debfile	= $(prefix)_all.deb
xkbpath	= usr/share/X11/xkb
testfile= $(xkbpath)/rules/README

MAKEFLAGS += --no-print-directory


.PHONY:	install uninstall _install reinstall-xkb-data
install:
	$(MAKE) _install R=

uninstall:
	$(MAKE) _install R=-R

_install:
	sudo find /$(xkbpath) -name '*.orig' -delete
	sudo find /$(xkbpath) -name '*.rej' -delete
	for f in patches/*--$(current).patch; do			\
	    [ -r "$$f" ] || continue;					\
	    echo "applying: $$f";					\
	    sudo patch -d /$(xkbpath) $(R) -p6 < $$f || ! break;	\
	    # Using "! break" works in many shells      ^^^^^^^		\
	    # https://unix.stackexchange.com/questions/340650#542698	\
	done
	sudo dpkg-reconfigure xkb-data

reinstall-xkb-data:
	sudo apt-get --reinstall install xkb-data


# The following entries are for working purposes only
$(prefix)_all.deb:
	mkdir -p dpkg
	curl -L -o $@ $(dpkgurl)

$(prefix).orig/$(testfile): $(prefix)_all.deb
	rm -rf $(prefix).orig
	mkdir -p $(prefix).orig
	cd $(prefix).orig && ar x ../../$<
	cd $(prefix).orig && tar -xpf control.tar.*
	cd $(prefix).orig && tar -xpf data.tar.*

$(prefix).edit/$(testfile): $(prefix).orig/$(testfile)
	rm -rf $(prefix).edit
	cp -a $(prefix).orig $(prefix).edit
	for f in patches/*--$(current).patch; do echo "applying: $$f";	\
	    [ -r "$$f" ] || continue;					\
	    patch -d $(prefix).edit/$(xkbpath) -p6 < $$f || ! break;	\
	done

diff.orig-vs-installed: dpkg/xkb-data_$(current).orig/$(testfile)
	diff -urN $(prefix).orig/$(xkbpath) /$(xkbpath) || :

diff.edit-vs-installed: dpkg/xkb-data_$(current).edit/$(testfile)
	diff -urN $(prefix).edit/$(xkbpath) /$(xkbpath) || :

diff.orig-vs-edit: dpkg/xkb-data_$(current).orig/$(testfile) dpkg/xkb-data_$(current).edit/$(testfile)
	diff -urN dpkg/xkb-data_$(current).orig dpkg/xkb-data_$(current).edit || :

.PHONY:	edit
edit: $(prefix).edit/$(testfile)

.PHONY:	clean
clean:
	rm -rf dpkg
