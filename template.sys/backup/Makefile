.PHONY:	default
default: usage

.PHONY:	usage help
usage help:
	@echo "usage: make [options]"	\
	"\noptions are:"		\
	"\n	backup [answer=yes|no]"	\
	"\n	diff [FILES=/etc/...]"	\
	"\n	nodiff"			\
	"\n"

.PHONY:	backup
backup:
	test -d orig -a -d new
	answer=$(answer) ./backup.sh

.PHONY:	diff
diff:
	test -d orig -a -d new
	set -o noglob; ./diff.sh $(FILES)

.PHONY:	nodiff
nodiff:
	test -d orig -a -d new
	./nodiff.sh
