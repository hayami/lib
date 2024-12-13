#!/bin/sh
umask 022
LANG=C
export LANG

PATH=/usr/bin:/bin; export PATH
for v in $(printenv | while read vv; do echo ${vv%%=*}; done); do
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

etc=$(cd /etc && pwd)
tmp=${TMPDIR:-/tmp}/$(basename $0).$$
trap "rm -rf $tmp.*; exit 1" 1 2 3 15
rm -rf $tmp.*
ext='=:='

###
### shell functions
###
echon() {
    printf '%s' "$*"
}

read_ans() {
    msg="$1"

    while :; do
        echon "$msg"
        if [ -z "$answer" ]; then
            read ans < /dev/tty
        else
            ans="$answer"
            echo "$ans"
        fi

        if [ "$ans" = "" ]; then	# default is "No"
            echo
            return 1
        fi
        
        case "$ans" in
        [yY]|[yY][eE][sS])
            echo
            return 0
            ;;
        [nN]|[nN][oO])
            echo
            return 1
            ;;
        esac
    done
}

epoch_touch() {
    TZ=UTC touch -h -t 197001010000.01 "$1"
}

backup_file() {
    etcorig="$1"
    etcfile=$(dirname "$etcorig")/$(basename "$etcorig" .orig)
    bang=$(echo "$etcfile" | sed -e 's#/#!#g')
    etcorigrm=0

    if [ -e "$etcorig" -a '(' ! -f "$etcorig" -a ! -L "$etcorig" ')' ]; then
        echo "WARNING: $etcorig is not a regular file, skipping"
        echon "WARNING: "; ls -ld "$etcorig"
        echo
        return
    fi

    if [ -e "$etcfile" -a '(' ! -f "$etcfile" -a ! -L "$etcfile" ')' ]; then
        echo "WARNING: $etcfile is not a regular file, skipping"
        echon "WARNING: "; ls -ld "$etcfile"
        echo
        continue
    fi

    if [ -e "orig/$bang" -a -e "orig/${bang}${ext}" ]; then
        echo "ERROR: duplicate backup file: $etcfile"
        echon "ERROR: "; ls -ld "orig/$bang"
        echon "ERROR: "; ls -ld "orig/${bang}${ext}"
        rm -rf $tmp.*
        exit 1
    fi

    if [ -e "new/$bang" -a -e "new/${bang}${ext}" ]; then
        echo "ERROR: duplicate backup file: $etcfile"
        echon "ERROR: "; ls -ld "new/$bang"
        echon "ERROR: "; ls -ld "new/${bang}${ext}"
        rm -rf $tmp.*
        exit 1
    fi

    if [ ! -L "$etcfile" -a -r "$etcfile" ]; then

        if [ -e "orig/$bang" ]; then
            echo "NOTICE: backup file exists: $etcfile"
            echon "NOTICE: "; ls -ld "orig/$bang"
            etcorigrm=1
        else
            if [ $($gfind "$etcorig" -printf "%m") -eq 0 ]; then
                cp -pi "$etcfile" "orig/$bang"
                : > "orig/$bang"
                epoch_touch "orig/$bang"
            else
                cp -pi "$etcorig" "orig/$bang"
            fi
            echo "INFO: backup file created: $etcorig"
            echon "INFO: "; ls -ld "orig/$bang"
            echo
            etcorigrm=1
        fi

        if [ ! -e "new/$bang" ]; then
            cp -pi "$etcfile" "new/$bang"
            echo "INFO: backup file created: $etcfile"
            echon "INFO: "; ls -ld "new/$bang"
            echo
        fi

    else

        if [ -e "orig/${bang}${ext}" ]; then
            echo "NOTICE: backup file exists: $etcfile"
            echon "NOTICE: "; ls -ld "orig/${bang}${ext}"
            etcorigrm=1
        else
            if [ $($gfind "$etcorig" -printf "%m") -eq 0 ]; then
                : > $tmp.epoch
                epoch_touch $tmp.epoch
                $gfind "$etcfile" -printf "%m %u:%g " > "orig/${bang}${ext}"
                $gfind $tmp.epoch -printf \
                "%s %TY-%Tm-%Td %TT $etcfile\n" >> "orig/${bang}${ext}"
                touch -h -r $tmp.epoch "orig/${bang}${ext}"
            else
                $gfind "$etcorig" -printf \
                "%m %u:%g %s %TY-%Tm-%Td %TT $etcfile" > "orig/${bang}${ext}"
                if [ -h "$etcorig" ]; then
                    $gfind "$etcorig" -printf " -> %l\n" >> "orig/${bang}${ext}"
                else
                    echo >> "orig/${bang}${ext}"
                fi
                touch -h -r "$etcorig" "orig/${bang}${ext}"
            fi
            echo "INFO: backup file created: $etcorig"
            echon "INFO: "; ls -ld "orig/${bang}${ext}"
            echon "INFO: "; cat "orig/${bang}${ext}"
            echo
            etcorigrm=1
        fi

        if [ ! -e "new/${bang}${ext}" ]; then
            $gfind "$etcfile" -printf \
            "%m %u:%g %s %TY-%Tm-%Td %TT $etcfile" > "new/${bang}${ext}"
            if [ -h "$etcfile" ]; then
                $gfind "$etcfile" -printf " -> %l\n" >> "new/${bang}${ext}"
            else
                echo >> "new/${bang}${ext}"
            fi
            touch -h -r "$etcfile" "new/${bang}${ext}"
            echo "INFO: backup file created: $etcfile"
            echon "INFO: "; ls -ld "new/${bang}${ext}"
            echon "INFO: "; cat "new/${bang}${ext}"
            echo
        fi

    fi

    [ $etcorigrm -eq 0 ] && return

    read_ans "NOTICE: Do you want to remove $etcorig [y/N]? " && sudo rm $etcorig
}

backup_dir_check() {
    a=$1
    b=$2

    $gfind $a -type f -printf "%P\n" | sort -u | while read bang; do
        if [ ! -f "$b/$bang" ]; then
            echo "WARNING: missing backup file: $b/$bang"
        fi
    done
}

backup_diff_check() {
    $gfind new -type f -printf "%P\n" | \
        sed -e 's/'"${ext}"'$//' | sort -u | while read bang; do
        etcfile=$(echo "$bang" | sed -e 's#!#/#g')

        if [ -e "new/$bang" -a -e "new/${bang}${ext}" ]; then
            echo "ERROR: duplicate backup file: $etcfile"
            echon "ERROR: "; ls -ld "new/$bang"
            echon "ERROR: "; ls -ld "new/${bang}${ext}"
            rm -rf $tmp.*
            exit 1
        fi

        if [ -r "$etcfile" -a -e "new/$bang" ]; then

            cmp "new/$bang" "$etcfile" > /dev/null 2>&1 && continue
            echo "WARNING: backup file may be out of date: $etcfile"
            diff -u "new/$bang" "$etcfile"
            echo

            read_ans "NOTICE: Do you want to update new/$bang [y/N]? "

            if [ $? -eq 0 ]; then
                cp -p "$etcfile" "new/$bang"
                if [ $? -eq 0 ]; then
                    echo "INFO: backup file updated: $etcfile"
                    echon "INFO: "; ls -ld "new/$bang"
                    echo
                fi
            fi

        else

            $gfind "$etcfile" -printf "%m %u:%g %s %TY-%Tm-%Td %TT %p" > $tmp.etc
            if [ -h "$etcfile" ]; then
                $gfind "$etcfile" -printf " -> %l\n" >> $tmp.etc
            else
                echo >> $tmp.etc
            fi
            cmp "new/${bang}${ext}" $tmp.etc > /dev/null 2>&1 && continue
            echo "WARNING: backup file may be out of date: $etcfile"
            diff -u "new/${bang}${ext}" $tmp.etc
            echo

            read_ans "NOTICE: Do you want to update new/$bang [y/N]? "

            if [ $? -eq 0 ]; then
                $gfind "$etcfile" -printf \
                "%m %u:%g %s %TY-%Tm-%Td %TT %p" > "new/${bang}${ext}"
                if [ -h "$etcfile" ]; then
                    $gfind "$etcfile" -printf " -> %l\n" >> "new/${bang}${ext}"
                else
                    echo >> "new/${bang}${ext}"
                fi
                touch -h -r "$etcfile" "new/${bang}${ext}"
                if [ $? -eq 0 ]; then
                    echo "INFO: backup file updated: $etcfile"
                    echon "INFO: "; ls -ld "new/${bang}${ext}"
                    echon "INFO: "; cat "new/${bang}${ext}"
                    echo
                fi
            fi
        fi

    done
}

###
### main
###
sudo true || exit 1
$gfind $etc -xdev -name '*.orig' 1> $tmp.out 2> $tmp.err
grep -E    '(^|/)g?find: .*: Permission denied$' $tmp.err > $tmp.err1
grep -E -v '(^|/)g?find: .*: Permission denied$' $tmp.err > $tmp.err2

if [ -s $tmp.err2 ]; then
    echo "ERROR: unexpected error as follows:"
    cat $tmp.err2
    rm -rf $tmp.*
    exit 1
fi

sed -n -E -e 's/(^|\/)g?find: `(.*)'"'"': Permission denied$/\2/p' $tmp.err1 \
| while read x; do
    sudo $gfind "$x" -xdev -name '*.orig' -print >> $tmp.err3
done
if [ -s $tmp.err3 ]; then
    echo "ERROR: can not access following files:"
    cat $tmp.err3
    rm -rf $tmp.*
    exit 1
fi


sort -u < $tmp.out | while read x; do
    backup_file "$x"
done

sudo $gfind $etc -xdev -name '*.orig' 1> $tmp.out 2> /dev/null
if [ -s $tmp.out ]; then
    echo 'WARNING: *.orig files not yet removed:'
    cat $tmp.out
    echo
fi

backup_dir_check orig new
backup_dir_check new orig
backup_diff_check

rm -rf $tmp.*
exit 0
