#!/bin/sh
set -e
umask 022

# for Windows 10: If there is no change in behavior after restarting Firefox,
# you may want to try deleting the scriptCache*.bin files in the
# %LOCALAPPDATA%\Mozilla\Firefox\Profiles\(profile)\startupCache\ directory.
#topdir='/mnt/c/Program Files/Mozilla Firefox'

# for Linux: The scriptCache*.bin files mentioned above are updated when
# Firefox is launched with the 'firefox --purgecaches' (A similar option
# may exist on Windows, but this has not been confirmed).
topdir="/usr/lib/firefox"


tmpdir=$(mktemp -d --tmpdir omni.XXXXXXXXXX)
targetpath=chrome/browser/content/browser/browser.xhtml
targetfile=$(basename $targetpath)


# customize browser.xhtml
customize() (
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


diffcolorless() (
    dh=/usr/share/doc/git/contrib/diff-highlight/diff-highlight
    if [ -f "$dh" ]; then
            env GIT_CONFIG_COUNT=2					\
                GIT_CONFIG_KEY_0=color.diff-highlight.oldHighlight	\
                GIT_CONFIG_VALUE_0='red bold'				\
                GIT_CONFIG_KEY_1=color.diff-highlight.newHighlight	\
                GIT_CONFIG_VALUE_1='green bold'				\
                perl "$dh"						\
            < "$1" | less -R
    else
            less "$1"
    fi
)


exitret=0
for omnipath in omni.ja browser/omni.ja; do

    if [ ! -f $topdir/$omnipath ]; then
        echo "ERROR: file not found: $topdir/$omnipath" 1>&2
        exitret=1
        continue
    fi

    xd=$tmpdir/${omnipath}--extract.d
    mkdir -p $xd

    #echo "Extracting: $topdir/$omnipath"
    ret=0
    unzip -q $topdir/$omnipath -d $xd > /dev/null 2>&1 || ret=$?
    #
    # Seems fine for the following warnings and errors.
    #   > warning [../omni.ja]:  43553032 extra bytes at beginning or within zipfile
    #   >   (attempting to process anyway)
    #   > error [../omni.ja]:  reported length of central directory is
    #   >   -43553032 bytes too long (Atari STZip zipfile?  J.H.Holm ZIPSPLIT 1.1
    #   >   zipfile?).  Compensating...
    #
    if [ $ret -gt 2 ]; then
        echo "ERROR: failed to unzip: $topdir/$omnipath" 1>&2
        rm -rf $xd
        exitret=1
        continue
    fi

    if [ ! -f $xd/$targetpath ]; then
        # browser.xhtml is not in omni.ja
        echo "ERROR: $targetfile is not found in $topdir/$omnipath" 1>&2
        rm -rf $xd
        exitret=1
        continue
    fi

    cp -p $xd/$targetpath $xd/$targetpath.orig
    customize $xd/$targetpath.orig > $xd/$targetpath.new
    lines=$(diff -u $xd/$targetpath $xd/$targetpath.new | wc -l)
    if [ $lines = 0 ]; then
        # browser.xhtml is edited but the result is the same as before
        echo "NOTICE: No text to edit in $targetfile in $topdir/$omnipath" 1>&2
        echo "NOTICE: or the $targetfile has already been customized. (skipping)" 1>&2
        rm -rf $xd
        continue
    fi

    cp -p $xd/$targetpath.orig $tmpdir/${omnipath}--$targetfile.orig
    cp -p $xd/$targetpath.new $tmpdir/${omnipath}--$targetfile.new
    diff -u $xd/$targetpath.orig $xd/$targetpath.new > $tmpdir/${omnipath}--$targetfile.diff || :

    cat $xd/$targetpath.new > $xd/$targetpath
    rm -f $xd/$targetpath.new
    rm -f $xd/$targetpath.orig

    cp -p $topdir/$omnipath $tmpdir/$omnipath.orig
    cp -p $topdir/$omnipath $tmpdir/$omnipath
    (cd $xd && zip -0DXqr - *) > $tmpdir/$omnipath.new

    ret=0
    cmp --quiet "$topdir/$omnipath" $tmpdir/$omnipath.new || ret=$?
    if [ $ret -eq 0 ]; then
        # omni.ja is updated but the result is the same as before
        echo "NOTICE: The updated file is no difference from before. (skipping)" 1>&2
        rm -rf $xd
        continue
    fi
    if [ $ret -eq 1 ]; then
        # omni.ja is updated and is different from the previous contents
        cat $tmpdir/$omnipath.new > $tmpdir/$omnipath
        rm -f $tmpdir/$omnipath.new

        diffcolorless $tmpdir/${omnipath}--$targetfile.diff
        echo "Updated file created: $tmpdir/$omnipath"
    fi
    rm -rf $xd
done

rmdir $tmpdir 2> /dev/null || :

exit $exitret
