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
##  umask
##
umask 022

##
##  PATH
##
PATH=/usr/bin:/bin; export PATH
p=
for dir in "$HOME/bin" "$HOME/sys/local/bin" "$HOME/sys/local/sbin" \
    /usr/local/bin /usr/local/sbin /usr/bin /usr/sbin /bin /sbin; do
    [ -d "$dir" ] && p="${p}${p:+:}${dir}"
done
PATH="$p"; export PATH
unset p dir

##
##  Language/Locale
##
LANG=ja_JP.UTF-8
TIME_STYLE=long-iso
export LANG TIME_STYLE

##
##  Pager
##
PAGER="/usr/bin/env SHELL=/bin/sh less"
LESS="-c -i -M -# 4 -R"
LESSOPEN="| lesspipe %s"
export PAGER LESS LESSOPEN

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

#P4PORT="perforce.example.jp:1666"
#P4USER=$USER
#P4CLIENT=`uname -n | sed -e 's:\..*::'`
#export P4PORT P4USER P4CLIENT

##  End of ~/.zshenv
