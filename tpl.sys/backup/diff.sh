#!/bin/sh
umask 022
LANG=C
export LANG
ext='=:='

find orig -type f -printf "%P\n" | sort -u | while read bang; do
    match=0
    if [ $# -eq 0 ]; then
        match=1
    else
        slash=$(echo "$bang" | sed -e 's#!#/#g' -e "s/$ext"'$//')
        for x in "$@"; do
            case "$slash" in
            $x) match=1
                break
                ;;
            esac
        done
    fi
    [ $match -eq 0 ] || diff -u "orig/${bang}" "new/${bang}"
done

exit 0
