#!/bin/sh
set -e
umask 022

# for Windows 10: If there is no change in behavior after restarting Firefox,
# you may want to try deleting the scriptCache*.bin files in the
# %LOCALAPPDATA%\Mozilla\Firefox\Profiles\(profile)\startupCache\ directory.
#topdir='/mnt/c/Program Files/Mozilla Firefox'
topdir='/snap/firefox'


tmpdir=$(mktemp -d --tmpdir omni.XXXXXXXXXX)
xhtmlpath=chrome/browser/content/browser/browser.xhtml
xhtmlname=$(basename $xhtmlpath)


substitute() (
    LAST_tag=
    LAST_id=
    LAST_modifiers=

    cat "$1" | while IFS= read line; do
        do_substitute=0
    for arg in $line; do
            case "$arg" in

            '<'*)
                LAST_tag="${arg#'<'}"
                ;;

            id=\"*\"*)
                x="$arg"
                x="${x#*=\"}"
                x="${x%\"*}"
                LAST_id="$x"
                ;;

            modifiers=\"*\"*)
                x="$arg"
                x="${x#*=\"}"
                x="${x%\"*}"
                LAST_modifiers="$x"
                ;;

            reserved=\"true\"*)
                do_substitute=1

                case "$LAST_tag" in
                key) ;;
                *) do_substitute=0 ;;
                esac

                case "$LAST_id" in
                key_close) ;;
                key_newNavigator) ;;
                key_newNavigatorTab) ;;
                *) do_substitute=0 ;;
                esac

                case "$LAST_modifiers" in
                accel) ;;
                *) do_substitute=0 ;;
                esac
            esac
        done

        if [ $do_substitute = 0 ]; then
            echo "$line"
        else
            echo "$line" | sed -e 's/reserved="true"/reserved="false"/'
        fi
    done
)


n=0
find "$topdir" ! -type l -type f -name omni.ja -printf "%P\n" | sort -u | while read omnipath; do
    n=$(($n + 1))
    xd=$tmpdir/extract.$n
    mkdir $xd

    #echo "Extracting: $topdir/$omnipath"
    ret=0
    unzip -q "$topdir/$omnipath" -d $xd > /dev/null 2>&1 || ret=$?
    #
    # Seems fine for the following warnings and errors.
    #   > warning [../omni.ja]:  43553032 extra bytes at beginning or within zipfile
    #   >   (attempting to process anyway)
    #   > error [../omni.ja]:  reported length of central directory is
    #   >   -43553032 bytes too long (Atari STZip zipfile?  J.H.Holm ZIPSPLIT 1.1
    #   >   zipfile?).  Compensating...
    #
    if [ $ret -gt 2 ]; then
        echo "Failed to unzip: $topdir/$omnipath" 1>&2
        rm -rf $xd
        continue
    fi

    if [ ! -f $xd/$xhtmlpath ]; then
        # browser.xhtml is not in omni.ja
        echo "Notice: $xhtmlname is not found in $topdir/$omnipath (skipping)" 1>&2
        continue;
    fi

    cp -pi $xd/$xhtmlpath $xd/$xhtmlpath.orig
    substitute $xd/$xhtmlpath.orig > $xd/$xhtmlpath.new
    lines=$(diff -u $xd/$xhtmlpath $xd/$xhtmlpath.new | wc -l)
    if [ $lines = 0 ]; then
        # browser.xhtml is edited but the result is the same as before
        echo "Notice: no matches found in $xhtmlname in $topdir/$omnipath (skipping)" 1>&2
        continue
    fi

    mkdir -p $tmpdir/$(dirname $omnipath)
    cp -pi $xd/$xhtmlpath.orig $tmpdir/$omnipath" ($xhtmlname)".orig
    cp -pi $xd/$xhtmlpath.new  $tmpdir/$omnipath" ($xhtmlname)".new
    diff -u $xd/$xhtmlpath.orig \
            $xd/$xhtmlpath.new > $tmpdir/$omnipath" ($xhtmlname)".diff || :

    cat $xd/$xhtmlpath.new > $xd/$xhtmlpath
    rm -f $xd/$xhtmlpath.new
    rm -f $xd/$xhtmlpath.orig

    cp -pi "$topdir/$omnipath" $tmpdir/$omnipath.orig
    cp -pi "$topdir/$omnipath" $tmpdir/$omnipath

    (cd $xd && zip -0DXqr - *) > $tmpdir/$omnipath.new

    ret=0
    cmp --quiet "$topdir/$omnipath" $tmpdir/$omnipath.new || ret=$?
    if [ $ret -eq 0 ]; then
        # omni.ja is modified but the result is the same as before
        echo "Notice: updated $topdir/$omnipath is identical to the original file (skipping)" 1>&2
        continue
    fi
    if [ $ret -eq 1 ]; then
        # omni.ja is modified and is different from the previous contents
        (cat $tmpdir/$omnipath.new > $tmpdir/$omnipath) 2> /dev/null || {
            chmod u+w $tmpdir/$omnipath
            cat $tmpdir/$omnipath.new > $tmpdir/$omnipath
            chmod u-w $tmpdir/$omnipath
        }
        rm -f $tmpdir/$omnipath.new

        echo "Updated file created: $tmpdir/$omnipath"
    fi
done

rm -rf $tmpdir/extract.*
rmdir $tmpdir 2> /dev/null || :

exit 0
