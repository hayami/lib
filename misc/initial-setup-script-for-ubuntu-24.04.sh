#!/bin/sh

# このスクリプトの利用例
#
#   (1) まずは guest でログイン
#       guest$ # このスクリプトを /var/tmp にコピーしてくる
#       guest$ # 例: /var/tmp/initial-setup-script-for-ubuntu-24.04.sh
#       guest$ sudo su - root -c '/bin/sh /var/tmp/initial-setup-script-*.sh'
#       guest$ sudo shutdown -r now
#
#   (2) 次に hayami でログイン
#       | これを選択 >>> (0)  Exit, creating the file ~/.zshrc ...
#       hayami% cd /var/tmp
#       hayami% sudo chown hayami: initial-setup-script-*.*
#       hayami% mv -i initial-setup-script-*.* ~/
#       hayami% cd
#       hayami% rm .zshrc .profile .bash*
#       hayami% git clone https://github.com/hayami/memo.git
#       hayami% git clone https://github.com/hayami/lib.git
#       hayami% cd lib
#       hayami% make install
#       hayami% cp -pi makefile-private-template ../private/lib/makefile
#       hayami% make relink
#       hayami% cd ~/sys/backup
#       hayami% make answer=yes backup


# (apt ではなく) apt-get を使用している理由 >>> 以下 man 8 apt より抜粋
#
# SCRIPT USAGE AND DIFFERENCES FROM OTHER APT TOOLS
#       The apt(8) commandline is designed as an end-user tool and it may
#       change behavior between versions. While it tries not to break backward
#       compatibility this is not guaranteed either if a change seems
#       beneficial for interactive use.
#
#       All features of apt(8) are available in dedicated APT tools like apt-
#       get(8) and apt-cache(8) as well.  apt(8) just changes the default value
#       some options (see apt.conf(5) and specifically the Binary scope). So
#       you should prefer using these commands (potentially with some
#       additional options enabled) in your scripts as they keep backward
#       compatibility as much as possible.


set -e
set -x
umask 022
export PATH=/usr/sbin:/usr/bin:/sbin:/bin
export LANG=C.UTF-8


###
### default values
###
guest=${guest:-'guest'}
hayami=${hayami:-'hayami'}

ipaddr=${ipaddr:-'dhcp'}
fqdn=${fqdn:-"$(hostname --fqdn)"}
newhostname=${newhostname:-"$(hostname --short)"}

sshaltport=${sshaltport:-'22'}
nobuildtools=${nobuildtools:-'0'}

# ref. https://unix.stackexchange.com/questions/746219
default_apt_get_options='--yes -qq'
default_apt_get_options="${default_apt_get_options} -o Dpkg::Progress-Fancy=0"
default_apt_get_options="${default_apt_get_options} -o APT::Color=0"
default_apt_get_options="${default_apt_get_options} -o Dpkg::Use-Pty=0"
opts=${apt_get_options:-"$default_apt_get_options"}


if [ -z "$updatehostname" ]; then
    if [ "$newhostname" = "$(hostname --short)" ]; then
        updatehostname=0
    else
        updatehostname=1
    fi
fi

case "$ipaddr" in
dhcp)   ipaddr='127.0.1.1' ;;
static) ipaddr=$(ip -4 -oneline address | sed -n -e 's#/.*##' -e 's#.* ##p' \
                | while read x; do case "$x" in (127.*) ;; (*) echo $x; break \
                ;; esac; done) ;;
*)      ;; # IPv4 address is assumed to be set in $ipaddr
esac

if [ -z "$log" ]; then
    log=$0
    log=${log%.sh}
    log=${log}.log
    case "$log" in
        /*)                       ;;
        ./*) log=$(pwd)/${log#./} ;;
        *)   log=$(pwd)/$log      ;;
    esac
fi


###
### start
###
(
    echo "*** $0 started at $(date)"
    cd /root
) 2>&1 | tee -a $log


###
### apt-get update
###
(
    echo "*** apt-get update"
    apt-get update
) 2>&1 | tee -a $log


###
### set debconf/priority to medium
###
#(
#    echo "*** debconf/priority"
#    # 'low' を設定すると、全ての項目について選択肢を提示するようなの
#    # で、その一つ上の 'medium' を設定してみる。デフォルト値は high。
#    # 設定可能な値: critical, high, medium, low
#    echo "debconf debconf/priority select medium" | debconf-set-selections
#    dpkg-reconfigure --frontend noninteractive debconf
#) 2>&1 | tee -a $log


###
### ufw
###
(
    echo "*** ufw"
    apt-get $opts install openssh-client openssh-server ufw
    ufw disable
    yes | ufw reset
    rm -f /etc/ufw/*.rules.*_*
    yes | ufw enable
    ufw default DENY
    ufw logging off
    if [ "$sshaltport" -eq 22 ]; then
        ufw allow OpenSSH
    else
        ufw allow $sshaltport/tcp
    fi
    ufw reload
    ufw status
) 2>&1 | tee -a $log


###
### /etc/hostname
###
(
    if [ $updatehostname -ne 0 ]; then
        echo "*** hostnamectl set-hostname $newhostname"
        hostnamectl set-hostname $newhostname
        echo "*** The hostname has been set to '$(hostname)'"
    fi

    echo "*** /etc/hostname"
    x=/etc/hostname; [ -f $x.orig ] || cp -p $x $x.orig
    [ $updatehostname -eq 0 ] || echo $newhostname > /etc/hostname
) 2>&1 | tee -a $log


###
### /etc/hosts
###
(
    echo "*** /etc/hosts"
    x=/etc/hosts; [ -f $x.orig ] || cp -p $x $x.orig
    if [ -z "$fqdn" ]; then
        a="$newhostname"
    elif [ "$newhostname" = "$fqdn" ]; then
        a="$newhostname"
    else
        a="$newhostname $fqdn"
    fi
    sed -i -e "s/^127[.]0[.]1[.]1\([ \t]\+\)[a-zA-Z0-9].*/$ipaddr\1$a/" $x
) 2>&1 | tee -a $log


###
### /etc/password, /etc/shadow, /etc/group, /etc/gshadow
###
(
    echo "*** /etc/passwd /etc/shadow /etc/group /etc/gshadow"
    for i in passwd shadow group gshadow; do
        x=/etc/$i; [ -f $x.orig ] || cp -p $x $x.orig
    done
) 2>&1 | tee -a $log


###
### set USERGROUPS_ENAB to 'no' in /etc/login.defs
###
(
    echo "*** /etc/login.defs"
    x=/etc/login.defs; [ -f $x.orig ] || cp -p $x $x.orig
    sed -i -e 's/^USERGROUPS_ENAB\([ \t]\+\)yes.*/USERGROUPS_ENAB\1no/' $x
    grep -E -q -e '^USERGROUPS_ENAB[[:blank:]]+no$' $x
) 2>&1 | tee -a $log


###
### NTP
###
(
    echo "*** ntp"
    x=/etc/systemd/timesyncd.conf; [ -f $x.orig ] || cp -p $x $x.orig
    if [ -f $x ] && ! grep -E -q '^NTP=' $x; then
        ed $x <<- 'EOF'
		/^[[]Time[]]
		a
		NTP=ntp.nict.jp
		.
		w
		q
		EOF
        sed -i -e '/^#NTP=/d' $x
        systemctl restart systemd-timesyncd
        systemctl status systemd-timesyncd
        timedatectl set-ntp true
        timedatectl status
    fi
) 2>&1 | tee -a $log


###
### /etc/fstab
###
(
    echo "*** /etc/fstab"
    x=/etc/fstab; [ -f $x.orig ] || cp -p $x $x.orig
) 2>&1 | tee -a $log


###
### /etc/nsswitch.conf
###
(
    echo "*** /etc/nsswitch.conf"
    x=/etc/nsswitch.conf; [ -f $x.orig ] || cp -p $x $x.orig
) 2>&1 | tee -a $log


###
### /etc/hosts.allow
###
(
    echo "*** /etc/hosts.allow"
    x=/etc/hosts.allow; [ -f $x.orig ] || cp -p $x $x.orig
    if ! grep -E -q -e '^ALL:' $x; then
        ed $x <<- 'EOF'
		$
		a
		ALL:	127.0.0.1 [::1]
		sshd:	ALL
		.
		w
		q
		EOF
    fi
) 2>&1 | tee -a $log


###
### /etc/hosts.deny
###
(
    echo "*** /etc/hosts.deny"
    x=/etc/hosts.deny; [ -f $x.orig ] || cp -p $x $x.orig
    if ! grep -E -q -e '^ALL:' $x; then
        ed $x <<- 'EOF'
		$
		a
		ALL:	ALL
		.
		w
		q
		EOF
    fi
) 2>&1 | tee -a $log


###
### /etc/ssh/sshd_config
###
(
    echo "*** /etc/ssh/sshd_config"
    x=/etc/ssh/sshd_config; [ -f $x.orig ] || cp -p $x $x.orig
    sed -i -e "s/^#.*Port\([ \t]\+\).*/Port\1$sshaltport/" $x
    grep -E -q -e "^Port[[:blank:]]+$sshaltport"'$' $x
    sed -i -e 's/^#.*PermitRootLogin\([ \t]\+\).*/PermitRootLogin\1no/' $x
    grep -E -q -e '^PermitRootLogin[[:blank:]]+no$' $x
    sed -i -e 's/^#.*UseDNS\([ \t]\+\).*/UseDNS\1yes/' $x
    grep -E -q -e '^UseDNS[[:blank:]]+yes$' $x
    if ! grep -E -q -e '^AllowGroups' $x; then
        ed $x <<- 'EOF'
		$
		a
		AllowGroups _ssh
		.
		w
		q
		EOF
    fi
) 2>&1 | tee -a $log


###
### adduser hayami
###
(
    echo "*** adduser $hayami"
    apt-get $opts install zsh
    if ! grep -E -q "^${hayami}:" /etc/passwd; then
        adduser --gecos $hayami --shell /bin/zsh --disabled-login $hayami
    fi
) 2>&1 | tee -a $log


###
### make sure directory permission on /home/$hayami
###
(
    x=$(eval echo "~$hayami")
    echo "*** directory permission on $x"
    b="(before) $(ls -ld $x)"
    chmod g-ws,o-rwxt $x
    a="(after)  $(ls -ld $x)"
    echo "$a\n$b"
) 2>&1 | tee -a $log


###
### add $hayami to all supplementary groups where $guest is registered
###
(
    echo "*** add $hayami to all suppl. groups where $guest is registered"
    u=$guest
    g=$(id -gn $u)
    suppG=$( (
        for i in $(id -Gn $u); do
            [ "$i" = "$g" ] || echo "$i"
        done
        echo 'sudo'
        echo 'users'
        echo '_ssh'
    ) | sort -u | tr '\n' ',' | sed -e 's/,$//')

    usermod -G $suppG $hayami
    usermod -G 'users,_ssh' $guest

) 2>&1 | tee -a $log


###
### remove sambashare group from hayami
###
(
    echo "*** sambashare"
    x=/etc/group
    if grep -E -q -e "^sambashare:.*$hayami" $x; then
        deluser $hayami sambashare
    fi
) 2>&1 | tee -a $log


###
### set password for hayami
###
(
    echo "*** passwd for $hayami"
    if grep -E -q "^${hayami}:.:" /etc/shadow; then
        passwd $hayami || passwd $hayami || passwd $hayami
    fi
) 2>&1 | tee -a $log


###
### disable login for guest
###
#(
#    echo "*** disable login for $guest"
#    usermod -p '*' $guest
#) 2>&1 | tee -a $log


###
### set system locale
###
(
    x=/etc/default/locale; [ -f $x.orig ] || cp -p $x $x.orig
    localectl status
    update-locale LANG=C.UTF-8
    localectl status
    localectl list-locales
) 2>&1 | tee -a $log


###
### set locales
###
(
    echo "*** locales for ja_JP.UTF-8"
    debconf-show locales
    x=/etc/locale.gen; [ -f $x.orig ] || mv $x $x.orig
    (
        echo -n 'locales'
        echo -n ' locales/default_environment_locale'
        echo -n ' select'
        echo -n ' C.UTF-8'
        echo
    ) | debconf-set-selections
    (
        echo -n 'locales'
        echo -n ' locales/locales_to_be_generated'
        echo -n ' multiselect'
        echo -n ' C.UTF-8 UTF-8'
        echo -n ', en_US.UTF-8 UTF-8'
        echo -n ', ja_JP.UTF-8 UTF-8'
        echo
    ) | debconf-set-selections
    rm -f /etc/locale.gen
    dpkg-reconfigure --frontend noninteractive locales
    ls -l /etc/locale.gen.orig /etc/locale.gen
    diff -u /etc/locale.gen.orig /etc/locale.gen || :
    debconf-show locales
    apt-get $opts install language-pack-ja
) 2>&1 | tee -a $log


###
### apt-get update upgrade full-upgrade autoremove autoclean clean
###         (and again) update
###
(
    echo "*** apt-get update upgrade full-upgrade autoremove autoclean clean update"
    apt-get update
    apt-get $opts upgrade
    apt-get $opts full-upgrade
    apt-get $opts autoremove
    apt-get $opts autoclean
    apt-get $opts clean
    apt-get update
) 2>&1 | tee -a $log


###
### install preferred packages
###
(
    echo "*** install preferred packages"
    apt-get $opts install language-pack-ja
    if [ "$nobuildtools" -ne 0 ]; then
        apt-get $opts install make
    else
        apt-get $opts install build-essential
        apt-get $opts install manpages manpages-dev
        apt-get $opts install manpages-posix manpages-posix-dev
    fi
    apt-get $opts install python3 python-is-python3
    apt-get $opts install net-tools curl git
    apt-get $opts install vim less
) 2>&1 | tee -a $log


###
### fix file permissions under /usr/local
###
(
    echo "*** file permissions under /usr/local (before)"
    find /usr/local ! -type l -perm /02020 -ls
    find /usr/local -group staff -ls
    find /usr/local -ls | sed -e 's/^[0-9 ]*//' | sort -u

    find /usr/local ! -type l -perm /02020 -exec chmod g-ws {} \;
    find /usr/local -group staff -exec chgrp -h root {} \;

    echo "*** file permissions under /usr/local (after)"
    find /usr/local ! -type l -perm /02020 -ls
    find /usr/local -group staff -ls
    find /usr/local -ls | sed -e 's/^[0-9 ]*//' | sort -u
) 2>&1 | tee -a $log


###
### finish
###
(
    echo "*** exit 0"
) 2>&1 | tee -a $log

exit 0
