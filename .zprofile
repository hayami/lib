##
##  A fix for macOS: Rebuild unacceptable PATH that was previously
##  overwritten by /usr/libexec/path_helper in /etc/zprofile
##
if [ "${_path+set}" = "set" ]; then
    if  [ -n "$_path" ] && [ "$_path" != "$PATH" ]; then
        extra=$(IFS=':'; for i in $(printf %s "$PATH"); do
            match=$(IFS=':'; for j in $(printf %s "$_path"); do
                [ "$i" != "$j" ] || echo YES
            done)
            [ -n "$match" ] || printf %s ":$i"
        done)

        PATH="${_path}${extra}"
        unset extra
    fi
    unset _path
fi
