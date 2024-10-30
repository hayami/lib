##
##  Set PATH against the setting in /usr/libexec/path_helper in /etc/zprofile
##
if [ -x /usr/libexec/path_helper ]; then
    p=
    for dir in						\
        $(find -L "$HOME/bin" -maxdepth 1		\
               -type d -print 2> /dev/null | sort) 	\
        $HOME/sys/local/bin $HOME/sys/local/sbin	\
        ${HOMEBREW_PREFIX:+$HOMEBREW_PREFIX/bin}	\
        ${HOMEBREW_PREFIX:+$HOMEBREW_PREFIX/sbin}	\
        /usr/local/bin /usr/local/sbin			\
        /snap/bin /usr/bin /usr/sbin /bin /sbin; do
        [ -d "$dir" ] && p="${p}${p:+:}${dir}"
    done

    extra=$(echo "$PATH" | tr ':' '\n' | while read i; do
        match=$(echo "$p" |  tr ':' '\n' | while read j; do
            [ "$i" != "$j" ] || echo YES
        done)
        [ -n "$match" ] || echo -n ":$i"
    done)

    PATH="${p}${extra}"
    unset p dir extra
fi
