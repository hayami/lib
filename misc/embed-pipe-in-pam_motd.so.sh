#!/bin/sh
umask 022
set -e
#set -x
export PATH=/usr/sbin:/usr/bin:/sbin:/bin
export LANG=C
cd /

TMPDIR=${TMPDIR:-/tmp}
tmpprefix=$TMPDIR/$$


cat_template() {
    cat <<- 'EOF'
	#!/bin/sh
	exec > /run/motd.dynamic.new
	PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
	LANG=C
	export PATH LANG
	grep -E -v -e '^[[:blank:]]*$'
	exit 0
	EOF
}


# First, check the status of binary data substitution
cd /lib/x86_64-linux-gnu/security

if strings -a -f pam_motd.so \
    | grep -F -q 'update-motd.d > /run/motd.dynamic.new'; then
    upstream=true
else
    upstream=false
fi

if strings -a -f pam_motd.so \
    | grep -F -q 'update-motd.d | /etc/motd.dynamic.new'; then
    modified=true
else
    modified=false
fi

case "${upstream}:${modified}" in
true:false)
    # Binary data substitution seems to be possible, go next
    ;;
false:true)
    echo "The pam_motd.so is already modified"
    exit 0
    ;;
*)
    echo "ERROR: got an unexpected status: ${upstream}:${modified}" 1>&2
    exit 1
    ;;
esac


# Set sudo if privileged or not
sudo=
[ $(id -u) -eq 0 ] || sudo=sudo


# Install the template script if script does not exist
if [ ! -x /etc/motd.dynamic.new ]; then
    cat_template | $sudo tee /etc/motd.dynamic.new > /dev/null
    $sudo chown root:root    /etc/motd.dynamic.new
    $sudo chmod 0755         /etc/motd.dynamic.new

    if [ ! -f /etc/motd.dynamic.new.orig ]; then
        $sudo TZ=UTC touch -t 197001010000 /etc/motd.dynamic.new.orig
        $sudo chown root:root              /etc/motd.dynamic.new.orig
        $sudo chmod 0                      /etc/motd.dynamic.new.orig
    fi
fi


# Do binary data substitution here
cd /lib/x86_64-linux-gnu/security
$sudo rm -f pam_motd.so.tmp
$sudo cp -a pam_motd.so pam_motd.so.tmp
$sudo cp -a pam_motd.so pam_motd.so.orig
$sudo sed -i 's#> /run/motd.dynamic.new#| /etc/motd.dynamic.new#' pam_motd.so.tmp


# Check that binary data substitution is as expected
cat <<- 'EOF' > ${tmpprefix}-pam_motd.so.diff.expected
	- 3e  >><
	+ 7c  >|<
	- 72  >r<
	- 75  >u<
	- 6e  >n<
	+ 65  >e<
	+ 74  >t<
	+ 63  >c<
	EOF
od -An -t x1z -w1 -v pam_motd.so.orig > ${tmpprefix}-pam_motd.so.hex.orig
od -An -t x1z -w1 -v pam_motd.so.tmp  > ${tmpprefix}-pam_motd.so.hex.tmp
diff -u ${tmpprefix}-pam_motd.so.hex.orig ${tmpprefix}-pam_motd.so.hex.tmp \
| grep -E -e '^[-+] ' > ${tmpprefix}-pam_motd.so.diff.out || :
cmp ${tmpprefix}-pam_motd.so.diff.expected ${tmpprefix}-pam_motd.so.diff.out

rm -f ${tmpprefix}-pam_motd.so.hex.orig
rm -f ${tmpprefix}-pam_motd.so.hex.tmp
rm -f ${tmpprefix}-pam_motd.so.diff.expected
rm -f ${tmpprefix}-pam_motd.so.diff.out


# Replacing the file now that the binary data substitution has been confirmed
$sudo mv pam_motd.so.tmp pam_motd.so
ls -l pam_motd.so pam_motd.so.orig

exit 0
