#!/bin/sh
umask 022
LANG=C
export LANG

PATH=/usr/bin:/bin; export PATH
for v in $(env -0 | tr '\n\0' '.\n' | sed 's/=.*//'); do
    case "$v" in
        (HOME|PATH|PWD|TERM|TMPDIR|TZ|USER) ;;
        (*) unset $v ;;
    esac
done

gfind=
for gf in $(
    for x in gfind find; do
        which -a $x
        for p in /usr/local/bin $HOME/sys/local/bin /opt/homebrew/bin; do
            [ ! -x $p/$x ] || echo $p/$x
        done
    done); do
    if $gf --version 2>&1 | grep 'GNU find' > /dev/null 2> /dev/null; then
        gfind=$gf
        break
    fi
done
if [ -z "$gfind" ]; then
    echo "ERROR: can not find GNU find"
    exit 1
fi

ext='=:='

$gfind orig -type f -printf "%P\n" | sort -u | while read bang; do
    etcfile=$(echo "$bang" | sed -e 's#!#/#g' -e 's/'"${ext}"'$//')
    cmp --quiet "orig/${bang}" "new/${bang}" && echo $etcfile
done

exit 0
