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
##  ~/.zshrc file for zsh(1).
##	This file is sourced only for interactive shells. It
##	should contain commands to set up aliases, functions,
##	options, key bindings, etc.
##
##  Global Order:
##	zshenv, zprofile, zshrc, zlogin
##

##
##  umask (again)
##
umask 022

##
##  Terminal Settings
##
# [ -n "$TMUX" ] || stty sane erase ''
[ "$TERM" = "" -o "$TERM" = "unknown" ] && export TERM=linux

##
##  Shell Prompt
##
PROMPT='%n@%m%% '

##
##  History Size
##
HISTSIZE=1000
SAVEHIST=1000
HISTFILE=~/.zhistory

##
##  Shell Functions
##
paj () { export LANG=C  }
jap () { export LANG=ja_JP.UTF-8 }

X() { echo 'Be care of Caps Lock!' 1>&2; /bin/false }

psg() {
    ps acx | tee /tmp/$$ | awk 'NR==1 {print $0}'
    egrep "$@" /tmp/$$ | egrep -v egrep
    rm -f /tmp/$$
}

unsetenvall () {
    PATH=/usr/bin:/bin; export PATH
    for x in `env | sed 's/=.*$//'`; do
        case "$x" in
            HOME|HOSTTYPE|LOGNAME|OSTYPE|PATH|PWD|TERM|TMPDIR|TZ|USER|_) ;;
            *) unset $x;;
        esac
    done
    env
}

grep-color () {
    if [ $# -eq 0 ]; then
        case "$GREP_OPTIONS" in
            *--color=never*)  x=       ;;
            *--color=auto*)   x=always ;;
            *--color=always*) x=never  ;;
            *--color=*)       x=auto   ;;
            *)                x=AUTO   ;;
        esac
        if [ -n "$x" ]; then
            case "$x" in
                [A-Z]*)
                    x=$(echo "$x" | tr '[A-Z]' '[a-z]')
                    [ -n "$GREP_OPTIONS" ] && GREP_OPTIONS="${GREP_OPTIONS} "
                    export GREP_OPTIONS="${GREP_OPTIONS}--color=$x"
                    ;;
                *)
                    GREP_OPTIONS="$(echo "$GREP_OPTIONS" | sed \
                                    -e 's/--color=[^ \t]*/--color='"$x"'/g')"
                    ;;
            esac
            echo "--color=$x"
        fi
    elif [ $# -eq 1 ]; then
        x=$(eval echo $1)
        x=${x%%' '*}
        case "$x" in
            au|aut|auto)              x=auto   ;;
            al|alw|alwa|alway|always) x=always ;;
            n|ne|nev|neve|never)      x=never  ;;
            -|'')                     x=       ;;
            *)
                echo "unexpected argument: '$1'" 1>&2
                return 1
                ;;
        esac
        if [ -n "$x" ]; then
            GREP_OPTIONS=$(echo "$GREP_OPTIONS" | sed \
                           -e 's/--color=[^ \t]*/--color='"$x"'/g')
            case "$GREP_OPTIONS" in
                *--color=*) ;;
                *)
                    [ -n "$GREP_OPTIONS" ] && GREP_OPTIONS="${GREP_OPTIONS} "
                    export GREP_OPTIONS="${GREP_OPTIONS}--color=$x"
                    ;;
            esac
            echo "--color=$x"
        fi
    else
        echo "Too many arguments" 1>&2
        return 1
    fi
    if [ -z "$x" ]; then
        GREP_OPTIONS="$(echo "$GREP_OPTIONS" | sed \
                        -e 's/[ \t]*--color=[^ \t]*[ \t]*/ /g' \
                        -e 's/^ //' -e 's/ $//')"
        [ -z "$GREP_OPTIONS" ] && unset GREP_OPTIONS
        echo "The --color option has been removed"
    fi
}

##
##  Aliases
##
alias ls="\ls $(args=
                for i in			\
                    -N				\
                    --show-control-chars	\
                    --color=auto		\
                    ; do
                    eval \\ls $args $i -ld / > /dev/null 2>&1 && args="$args $i"
                done
                eval echo $args)"
alias ll='ls -Al'
alias sl='ls'
alias less="${PAGER:-'less'}"
alias vi='vim'
alias view='vim -R'
alias cu='cu --parity=none --nostop'
#         cu --parity=none --nostop --line /dev/ttyUSB0 --speed 115200 dir
#alias lpr='lpr -h'

##
##  Enabling Completion
##
autoload -U compinit
compinit

##
##  Search path for the cd command
##
#CDPATH=/path/to/dir1:/path/to/dir2
CDPATH=

##
##  Filename completion suffixes to ignore
##
FIGNORE=\~:.bak:.orig:.o

##
##  Max listing lines (see 'man zshparam' for more details)
##
LISTMAX=0

##
##  Some nice key bindings
##
##  If one of the VISUAL or EDITOR environment variables contain the string
##  'vi' when the shell starts up then it will be 'viins', otherwise it will
##  be 'emacs'. bindkey's -e and -v options provide a convenient way to
##  override this default choice.
##
bindkey -e		# emacs key bindings

##
##  setopt options (see 'man zshoptions' for more details)
##  type 'set -o' to see all options
##
setopt correct
setopt auto_pushd	# type "cd -<TAB>" to list dirs
setopt pushd_ignore_dups
setopt append_history
setopt hist_ignore_space
setopt hist_verify
setopt no_beep
setopt list_packed
#setopt no_auto_remove_slash

##
##  Hostname Completion
##
_cache_hosts=(localhost mikado tako garlic)

##
##  Private Settings
##
if [ -r ~/.zshrc-private ]; then
    . ~/.zshrc-private
fi

##  End of ~/.zshrc
