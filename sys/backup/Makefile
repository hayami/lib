.PHONY:	default
default: usage

.PHONY:	usage help
usage help:
	@echo "usage: make [options]"	\
	"\noptions are:"		\
	"\n	backup"			\
	"\n	diff [FILES=/etc/...]"	\
	"\n	nodiff"			\
	"\n"

.PHONY:	backup
backup:
	./backup.sh

.PHONY:	diff
diff:
	./diff.sh $(FILES)

.PHONY:	nodiff
nodiff:
	./nodiff.sh
