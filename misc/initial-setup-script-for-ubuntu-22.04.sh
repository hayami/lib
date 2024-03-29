#!/bin/sh

# このスクリプトの利用例
#	$ ssh guest@remote
#	guest$ # このスクリプトを /var/tmp にコピーしてくる
#	guest$ # 例: /var/tmp/initial-setup-script-for-ubuntu-22.04.sh
#	guest$ sudo su - root -c '/bin/sh /var/tmp/initial-setup-script-*.sh'
#	guest$ sudo shutdown -r now
#	$ ssh hayami@remote
#	| これを選択 >>> (0)  Exit, creating the file ~/.zshrc ...
#	hayami% cd /var/tmp
#	hayami% sudo chown hayami: initial-setup-script-*.log
#	hayami% mv -i initial-setup-script-*.log ~/
#	hayami% cd
#	hayami% rm .zshrc .profile .bash*
#	hayami% git clone https://github.com/hayami/memo.git
#	hayami% git clone https://github.com/hayami/dot.git
#	hayami% cd dot
#	hayami% make install
#	hayami% cp -pi makefile-private-template ../private/dot/makefile
#	hayami% make relink
#	hayami% cd ~/sys/backup
#	hayami% make answer=yes backup

set -e
set -x
umask 022
export PATH=/usr/sbin:/usr/bin:/sbin:/bin
export LANG=C


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


if [ -z "$updatehostname" ]; then
    if [ "$newhostname" = "$(hostname --short)" ]; then
        updatehostname=0
    else
        updatehostname=1
    fi
fi

case "$ipaddr" in
dhcp)	ipaddr='127.0.1.1' ;;
static)	ipaddr=$(ip -4 -oneline address | sed -n -e 's#/.*##' -e 's#.* ##p' \
		| while read x; do case "$x" in (127.*) ;; (*) echo $x; break \
		;; esac; done) ;;
*)	;; # IPv4 address is assumed to be set in $ipaddr
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
echo "*** $0 started at $(date)" >> $log
cd /root


###
### apt-get update
###
echo "*** apt-get update"	>> $log
apt-get update			>> $log


###
### set debconf/priority to medium
###
echo "*** debconf/priority"	>> $log
# 'low' を設定すると、全ての項目について選択肢を提示するようなの
# で、その一つ上の 'medium' を設定してみる。デフォルト値は high。
# 設定可能な値: critical, high, medium, low
echo "debconf debconf/priority select medium" | debconf-set-selections
dpkg-reconfigure --frontend noninteractive debconf


###
### ufw
###
echo "*** ufw"			>> $log
apt-get install ufw		>> $log
ufw disable			>> $log
yes | ufw reset			>> $log
rm -f /etc/ufw/*.rules.*_*
yes | ufw enable		>> $log
ufw default DENY		>> $log
ufw logging off			>> $log
if [ "$sshaltport" -eq 22 ]; then
    ufw allow OpenSSH		>> $log
else
    ufw allow $sshaltport/tcp	>> $log
fi
ufw reload			>> $log
ufw status			>> $log


###
### /etc/hostname
###
if [ $updatehostname -ne 0 ]; then
    echo "*** hostnamectl set-hostname $newhostname"		>> $log
    hostnamectl set-hostname $newhostname
    echo "*** The hostname has been set to '$(hostname)'"	>> $log
fi

echo "*** /etc/hostname" >> $log
x=/etc/hostname; [ -f $x.orig ] || cp -p $x $x.orig
[ $updatehostname -eq 0 ] || echo $newhostname > /etc/hostname


###
### /etc/hosts
###
echo "*** /etc/hosts" >> $log
x=/etc/hosts; [ -f $x.orig ] || cp -p $x $x.orig
if [ -z "$fqdn" ]; then
    a="$newhostname"
elif [ "$newhostname" = "$fqdn" ]; then
    a="$newhostname"
else
    a="$newhostname $fqdn"
fi
sed -i -e "s/^127[.]0[.]1[.]1\([ \t]\+\)[a-zA-Z0-9].*/$ipaddr\1$a/" $x


###
### /etc/password, /etc/shadow, /etc/group, /etc/gshadow
###
echo "*** /etc/passwd /etc/shadow /etc/group /etc/gshadow" >> $log
for i in passwd shadow group gshadow; do
    x=/etc/$i; [ -f $x.orig ] || cp -p $x $x.orig
done


###
### set USERGROUPS_ENAB to 'no' in /etc/login.defs
###
echo "*** /etc/login.defs" >> $log
x=/etc/login.defs; [ -f $x.orig ] || cp -p $x $x.orig
sed -i -e 's/^USERGROUPS_ENAB\([ \t]\+\)yes.*/USERGROUPS_ENAB\1no/' $x
egrep -q -e '^USERGROUPS_ENAB[[:blank:]]+no$' $x


###
### NTP
###
echo "*** ntp" >> $log
x=/etc/systemd/timesyncd.conf; [ -f $x.orig ] || cp -p $x $x.orig
if [ -f $x ] && ! egrep -q '^NTP=' $x; then
    ed $x <<- 'EOF' >> $log
	/^[[]Time[]]
	a
	NTP=ntp.nict.jp
	.
	w
	q
	EOF
    sed -i -e '/^#NTP=/d' $x		>> $log
    systemctl restart systemd-timesyncd	>> $log
    systemctl status systemd-timesyncd	>> $log
    timedatectl set-ntp true		>> $log
    timedatectl status			>> $log
fi


###
### /etc/fstab
###
echo "*** /etc/fstab" >> $log
x=/etc/fstab; [ -f $x.orig ] || cp -p $x $x.orig


###
### /etc/nsswitch.conf
###
echo "*** /etc/nsswitch.conf" >> $log
x=/etc/nsswitch.conf; [ -f $x.orig ] || cp -p $x $x.orig


###
### /etc/hosts.allow
###
echo "*** /etc/hosts.allow" >> $log
x=/etc/hosts.allow; [ -f $x.orig ] || cp -p $x $x.orig
if ! egrep -q -e '^ALL:' $x; then
    ed $x <<- 'EOF' >> $log
	$
	a
	ALL:	127.0.0.1 [::1]
	sshd:	ALL
	.
	w
	q
	EOF
fi


###
### /etc/hosts.deny
###
echo "*** /etc/hosts.deny" >> $log
x=/etc/hosts.deny; [ -f $x.orig ] || cp -p $x $x.orig
if ! egrep -q -e '^ALL:' $x; then
    ed $x <<- 'EOF' >> $log
	$
	a
	ALL:	ALL
	.
	w
	q
	EOF
fi


###
### /etc/ssh/sshd_config
###
echo "*** /etc/ssh/sshd_config" >> $log
x=/etc/ssh/sshd_config; [ -f $x.orig ] || cp -p $x $x.orig
sed -i -e "s/^#.*Port\([ \t]\+\).*/Port\1$sshaltport/" $x
egrep -q -e "^Port[[:blank:]]+$sshaltport"'$' $x
sed -i -e 's/^#.*PermitRootLogin\([ \t]\+\).*/PermitRootLogin\1no/' $x
egrep -q -e '^PermitRootLogin[[:blank:]]+no$' $x
sed -i -e 's/^#.*UseDNS\([ \t]\+\).*/UseDNS\1yes/' $x
egrep -q -e '^UseDNS[[:blank:]]+yes$' $x
if ! egrep -q -e '^AllowGroups' $x; then
    ed $x <<- 'EOF' >> $log
	$
	a
	AllowGroups _ssh
	.
	w
	q
	EOF
fi


###
### adduser hayami
###
echo "*** adduser $hayami"	>> $log
apt-get --yes install zsh	>> $log
if ! egrep -q "^${hayami}:" /etc/passwd; then
    adduser --gecos $hayami --shell /bin/zsh --disabled-login $hayami
fi


###
### swap guest and hayami
###
echo "*** swap $guest and $hayami" >> $log
x=/etc/group
if egrep -q -e "[:,]$guest"'$' $x; then
    sed -i -e "s/\([:,]\)$guest/\1$hayami/g" $x
fi
x=/etc/gshadow
if egrep -q -e "[:,]$guest"'$' $x; then
    sed -i -e "s/\([:,]\)$guest/\1$hayami/g" $x
fi


###
### remove sambashare group from hayami
###
echo "*** sambashare" >> $log
x=/etc/group
if egrep -q -e "^sambashare:.*$hayami" $x; then
    deluser $hayami sambashare
fi


###
### add _ssh group to guest and hayami
###
echo "*** adduser $guest _ssh" >> $log
x=/etc/group
if ! egrep -q -e "^_ssh:.*$guest" $x; then
    adduser $guest _ssh
fi

echo "*** adduser $hayami _ssh" >> $log
x=/etc/group
if ! egrep -q -e "^_ssh:.*$hayami" $x; then
    adduser $hayami _ssh
fi


###
### set password for hayami
###
echo "*** passwd for $hayami" >> $log
if egrep -q "^${hayami}:.:" /etc/shadow; then
    passwd $hayami || passwd $hayami || passwd $hayami
fi


###
### disable login for guest
###
#echo "*** disable login for $guest" >> $log
#usermod -p '*' $guest


###
### set locales
###
echo "*** locales for ja_JP.UTF-8"		>> $log
debconf-show locales				>> $log
x=/etc/locale.gen; [ -f $x.orig ] || mv $x $x.orig
(
    echo -n 'locales'
    echo -n ' locales/locales_to_be_generated'
    echo -n ' multiselect'
    echo -n ' en_US ISO-8859-1'
    echo -n ', en_US.UTF-8 UTF-8'
    echo -n ', ja_JP.UTF-8 UTF-8'
    echo
) | debconf-set-selections
dpkg-reconfigure --frontend noninteractive locales
ls -l /etc/locale.gen.orig /etc/locale.gen	>> $log
diff -u /etc/locale.gen.orig /etc/locale.gen	>> $log || :
debconf-show locales				>> $log
apt-get --yes install language-pack-ja		>> $log


###
### set system locale
###
x=/etc/default/locale; [ -f $x.orig ] || cp -p $x $x.orig
localectl status		>> $log
update-locale LANG=C.UTF-8	>> $log
localectl status		>> $log
localectl list-locales		>> $log


###
### apt-get update upgrade dist-upgrade autoremove clean (and again) update
###
echo "*** apt-get update upgrade dist-upgrade autoremove clean update" >> $log
apt-get update			>> $log
apt-get --yes upgrade		>> $log
apt-get --yes dist-upgrade	>> $log
apt-get autoremove		>> $log
apt-get clean			>> $log
apt-get update			>> $log


###
### install preferred packages
###
echo "*** install preferred packages"					>> $log
apt-get --yes install language-pack-ja					>> $log
if [ "$nobuildtools" -ne 0 ]; then
    apt-get --yes install make
else
    apt-get --yes install build-essential				>> $log
    apt-get --yes install manpages manpages-dev				>> $log
    apt-get --yes install manpages-posix manpages-posix-dev		>> $log
fi
apt-get --yes install python2 python3					>> $log
apt-get --yes install python-is-python3					>> $log
apt-get --yes install net-tools curl git				>> $log
apt-get --yes install vim less						>> $log


###
### fix file permissions undoer /usr/local
###
echo "*** file permissions under /usr/local (before)"			>> $log
find /usr/local ! -type l -perm /02020 -ls				>> $log
find /usr/local -group staff -ls					>> $log
find /usr/local -ls | sed -e 's/^[0-9 ]*//' | sort -u			>> $log

find /usr/local ! -type l -perm /02020 -exec chmod g-ws {} \;
find /usr/local -group staff -exec chgrp -h root {} \;

echo "*** file permissions under /usr/local (after)"			>> $log
find /usr/local ! -type l -perm /02020 -ls				>> $log
find /usr/local -group staff -ls					>> $log
find /usr/local -ls | sed -e 's/^[0-9 ]*//' | sort -u			>> $log


###
### finish
###
echo "*** exit 0" >> $log
exit 0
