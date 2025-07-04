##
##  STARTUP/SHUTDOWN FILES
##	Commands are first read from /etc/zshenv.  If the RCS option
##	is  unset within /etc/zshenv, all other initialization files
##	are   skipped.    Otherwise,   commands   are   read    from
##	$ZDOTDIR/.zshenv.   (If  ZDOTDIR  is  unset,  HOME  is  used
##	instead).  If the first character of argument zero passed to
##	the shell is -, or if the -l flag is present, then the shell
##	is assumed to be a login shell, and commands are  read  from
##	/etc/zprofile  and  then  $ZDOTDIR/.zprofile.   Then, if the
##	shell is interactive, commands are read from /etc/zshrc  and
##	then  $ZDOTDIR/.zshrc.   Finally,  if  the  shell is a login
##	shell, /etc/zlogin and $ZDOTDIR/.zlogin are read.
##
##  ~/.zshenv file for zsh(1).
##	This file is sourced on all invocations of the shell.
##	If the -f flag is present or if the NO_RCS option is
##	set within this file, all other initialization files
##	are skipped.
##
##	This file should contain commands to set the command
##	search path, plus other important environment variables.
##	This file should not contain commands that produce
##	output or assume the shell is attached to a tty.
##
##  Global Order:
##	zshenv, zprofile, zshrc, zlogin

##
##  CAUTION: This files is sourced by /bin/sh (Bourn Shell) in .xsession file.
##

##
##  Pre Hook
##
if [ -r ~/.zshenv-prehook ]; then
    . ~/.zshenv-prehook
fi

##
##  umask
##
umask 022

##
##  Homebrew
##
if [ -z "$HOMEBREW_PREFIX" ]; then
    test_brew=/opt/homebrew/bin/brew
    export HOMEBREW_PREFIX=$($test_brew --prefix 2> /dev/null)
    export HOMEBREW_CELLAR=$($test_brew --cellar 2> /dev/null)
    export HOMEBREW_REPOSITORY=$($test_brew --repository 2> /dev/null)
    [ -n "$HOMEBREW_PREFIX"     ] || unset HOMEBREW_PREFIX
    [ -n "$HOMEBREW_CELLAR"     ] || unset HOMEBREW_CELLAR
    [ -n "$HOMEBREW_REPOSITORY" ] || unset HOMEBREW_REPOSITORY
    unset test_brew
fi

##
##  PATH
##
PATH=/usr/bin:/bin; export PATH
prefixes="$HOME/sys/local $HOMEBREW_PREFIX /usr/local"
p=
for dir in \
    $(find -L "$HOME/bin" -maxdepth 1 -type d -print 2> /dev/null | sort) \
    $(for pref in ${=prefixes}; do echo $pref/bin; echo $pref/sbin; done) \
    /snap/bin /usr/bin /usr/sbin /bin /sbin; do
    [ -d "$dir" ] && p="${p}${p:+:}${dir}"
done
PATH="$p"; export PATH
unset p dir prefixes
[[ -o login ]] && _path="$PATH"	# see ~/.zprofile for this _path variable

##
##  Language/Locale
##
LANG=ja_JP.UTF-8
TIME_STYLE=long-iso
export LANG TIME_STYLE

##
##  unset LC_*
##
for v in $(printenv | while read vv; do echo ${vv%%=*}; done); do
    case "$v" in
    LC_*) unset $v ;;
    esac
done
unset v

##
##  Pager
##
PAGER="/usr/bin/env SHELL=/bin/sh less"
LESS="-c -i -M -# 4 -R"
export PAGER LESS
for i in lesspipe lesspipe.sh; do
    if which $i > /dev/null 2>&1; then
        LESSOPEN="| $i %s"
        export LESSOPEN
        break
    fi
done
unset v

##
##  Editor
##
EDITOR=vim
export EDITOR

##
##  Others
##
#ftp_proxy="http://proxy.example.jp:8080/"
#http_proxy="http://proxy.example.jp:8080/"
#https_proxy="http://proxy.example.jp:8080/"
#export ftp_proxy http_proxy https_proxy

##
##  Post Hook
##
if [ -r ~/.zshenv-posthook ]; then
    . ~/.zshenv-posthook
fi

##  End of ~/.zshenv
