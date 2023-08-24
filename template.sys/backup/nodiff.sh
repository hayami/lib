#!/bin/sh
umask 022
LANG=C
export LANG
ext='=:='

find orig -type f -printf "%P\n" | sort -u | while read bang; do
    etcfile=`echo "$bang" | sed -e 's#!#/#g' -e 's/'"${ext}"'$//'`
    cmp --quiet "orig/${bang}" "new/${bang}" && echo $etcfile
done

exit 0
