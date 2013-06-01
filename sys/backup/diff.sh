#!/bin/sh
umask 022
LANG=C
export LANG
ext='=:='

if [ $# -eq 0 ]; then
    find orig -type f -printf "%P\n" | sort -u | while read bang; do
        diff -u "orig/${bang}" "new/${bang}"
    done
else
    while [ $# -gt 0 ]; do
        bang=`echo "$1" | sed -e 's#/#!#g'`
        if [ -e "orig/${bang}" -a -e "new/${bang}" ]; then
            diff -u "orig/${bang}" "new/${bang}"
        fi
        if [ -e "orig/${bang}${ext}" -a -e "new/${bang}${ext}" ]; then
            diff -u "orig/${bang}${ext}" "new/${bang}${ext}"
        fi

        shift
    done
fi

exit 0
