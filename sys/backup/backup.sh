#!/bin/sh
umask 022
LANG=C
export LANG
ext='=:='

tmp=/tmp/`basename $0`.$$
trap "rm -rf $tmp.*; exit 1" 1 2 3 15
rm -rf $tmp.*

###
### shell functions
###

read_ans() {
    msg="$1"

    while :; do
        echo -n "$msg"
        read ans < /dev/tty

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
    TZ=UTC touch -t 197001010000.01 "$1"
}

backup_file() {
    etcorig="$1"
    etcfile=`dirname "$etcorig"`/`basename "$etcorig" .orig`
    bang=`echo "$etcfile" | sed -e 's#/#!#g'`
    etcorigrm=0

    if [ -e "$etcorig" -a '(' ! -f "$etcorig" -o -L "$etcorig" ')' ]; then
        echo "WARNING: $etcorig is not a regular file, skipping"
        echo -n "WARNING: "; ls -ld "$etcorig"
        echo
        return
    fi

    if [ -e "$etcfile" -a '(' ! -f "$etcfile" -o -L "$etcfile" ')' ]; then
        echo "WARNING: $etcfile is not a regular file, skipping"
        echo -n "WARNING: "; ls -ld "$etcfile"
        echo
        continue
    fi

    if [ -e "orig/$bang" -a -e "orig/${bang}${ext}" ]; then
        echo "ERROR: duplicate backup file: $etcfile"
        echo -n "ERROR: "; ls -ld "orig/$bang"
        echo -n "ERROR: "; ls -ld "orig/${bang}${ext}"
        rm -rf $tmp.*
        exit 1
    fi

    if [ -e "new/$bang" -a -e "new/${bang}${ext}" ]; then
        echo "ERROR: duplicate backup file: $etcfile"
        echo -n "ERROR: "; ls -ld "new/$bang"
        echo -n "ERROR: "; ls -ld "new/${bang}${ext}"
        rm -rf $tmp.*
        exit 1
    fi

    if [ -r "$etcfile" ]; then

        if [ -e "orig/$bang" ]; then
            echo "NOTICE: backup file exists: $etcfile"
            echo -n "NOTICE: "; ls -ld "orig/$bang"
            etcorigrm=1
        else
            if [ `find "$etcorig" -printf "%m"` -eq 0 ]; then
                cp -pi "$etcfile" "orig/$bang"
                : > "orig/$bang"
                epoch_touch "orig/$bang"
            else
                cp -pi "$etcorig" "orig/$bang"
            fi
            echo "INFO: backup file created: $etcorig"
            echo -n "INFO: "; ls -ld "orig/$bang"
            echo
            etcorigrm=1
        fi

        if [ ! -e "new/$bang" ]; then
            cp -pi "$etcfile" "new/$bang"
            echo "INFO: backup file created: $etcfile"
            echo -n "INFO: "; ls -ld "new/$bang"
            echo
        fi

    else

        if [ -e "orig/${bang}${ext}" ]; then
            echo "NOTICE: backup file exists: $etcfile"
            echo -n "NOTICE: "; ls -ld "orig/${bang}${ext}"
            etcorigrm=1
        else
            if [ `find "$etcorig" -printf "%m"` -eq 0 ]; then
                : > $tmp.epoch
                epoch_touch $tmp.epoch
                find "$etcfile" -printf "%m %u:%g " > "orig/${bang}${ext}"
                find $tmp.epoch -printf \
                "%s %TY-%Tm-%Td %TT $etcfile\n" >> "orig/${bang}${ext}"
                touch -r $tmp.epoch "orig/${bang}${ext}"
            else
                find "$etcorig" -printf \
                "%m %u:%g %s %TY-%Tm-%Td %TT $etcfile\n" > "orig/${bang}${ext}"
                touch -r "$etcorig" "orig/${bang}${ext}"
            fi
            echo "INFO: backup file created: $etcorig"
            echo -n "INFO: "; ls -ld "orig/${bang}${ext}"
            echo -n "INFO: "; cat "orig/${bang}${ext}"
            echo
            etcorigrm=1
        fi

        if [ ! -e "new/${bang}${ext}" ]; then
            find "$etcfile" -printf "%m %u:%g %s %TY-%Tm-%Td %TT $etcfile\n" \
            > "new/${bang}${ext}"
            touch -r "$etcfile" "new/${bang}${ext}"
            echo "INFO: backup file created: $etcfile"
            echo -n "INFO: "; ls -ld "new/${bang}${ext}"
            echo -n "INFO: "; cat "new/${bang}${ext}"
            echo
        fi

    fi

    [ $etcorigrm -eq 0 ] && return

    read_ans "NOTICE: Do you remove $etcorig [y/N]? " && sudo rm $etcorig
}

backup_dir_check() {
    a=$1
    b=$2

    find $a -type f -printf "%P\n" | sort -u | while read bang; do
        if [ ! -f "$b/$bang" ]; then
            echo "WARNING: missing backup file: $b/$bang"
        fi
    done
}

backup_diff_check() {
    find new -type f -printf "%P\n" | \
        sed -e 's/'"${ext}"'$//' | sort -u | while read bang; do
        etcfile=`echo "$bang" | sed -e 's#!#/#g'`

        if [ -e "new/$bang" -a -e "new/${bang}${ext}" ]; then
            echo "ERROR: duplicate backup file: $etcfile"
            echo -n "ERROR: "; ls -ld "new/$bang"
            echo -n "ERROR: "; ls -ld "new/${bang}${ext}"
            rm -rf $tmp.*
            exit 1
        fi

        if [ -r "$etcfile" ]; then

            cmp "new/$bang" "$etcfile" > /dev/null 2>&1 && continue
            echo "WARNING: backup file may be out of date: $etcfile"
            diff -u "new/$bang" "$etcfile"
            echo

            read_ans "NOTICE: Do you want to update new/$bang [y/N]? "

            if [ $? -eq 0 ]; then
                cp -p "$etcfile" "new/$bang"
                if [ $? -eq 0 ]; then
                    echo "INFO: backup file updated: $etcfile"
                    echo -n "INFO: "; ls -ld "new/$bang"
                    echo
                fi
            fi

        else

            find "$etcfile" -printf "%m %u:%g %s %TY-%Tm-%Td %TT %p\n" \
            > $tmp.etc
            cmp "new/${bang}${ext}" $tmp.etc > /dev/null 2>&1 && continue
            echo "WARNING: backup file may be out of date: $etcfile"
            diff -u "new/${bang}${ext}" $tmp.etc
            echo

            read_ans "NOTICE: Do you want to update new/$bang [y/N]? "

            if [ $? -eq 0 ]; then
                find "$etcfile" -printf "%m %u:%g %s %TY-%Tm-%Td %TT %p\n" \
                > "new/${bang}${ext}" && touch -r "$etcfile" "new/${bang}${ext}"
                if [ $? -eq 0 ]; then
                    echo "INFO: backup file updated: $etcfile"
                    echo -n "INFO: "; ls -ld "new/${bang}${ext}"
                    echo -n "INFO: "; cat "new/${bang}${ext}"
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
find /etc -xdev -name '*.orig' 1> $tmp.out 2> $tmp.err
egrep    '^find: .*: Permission denied$' $tmp.err > $tmp.err1
egrep -v '^find: .*: Permission denied$' $tmp.err > $tmp.err2

if [ -s $tmp.err2 ]; then
    echo "ERROR: unexpected error as follows:"
    cat $tmp.err2
    rm -rf $tmp.*
    exit 1
fi

sed -n -e 's/^find: `\(.*\)'"'"': Permission denied$/\1/p' $tmp.err1 \
| while read x; do
    sudo find "$x" -xdev -name '*.orig' -print >> $tmp.err3
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

sudo find /etc -xdev -name '*.orig' 1> $tmp.out 2> /dev/null
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
