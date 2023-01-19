#/bin/sh

# Ref: How do I swap mouse buttons to be left handed from the terminal?
#      https://askubuntu.com/questions/151819/how-do-i-swap-mouse-buttons-to-be-left-handed-from-the-terminal

set -e

devregex=${1:-'Logi.*Mouse'}

devid=$(xinput list | sed -n -e 's/.*'"$devregex"'.*id=\([0-9]\+\).*/\1/p')
if [ -z "$devid" ]; then
    echo "ERROR: not found: $devregex" 1>&2
    exit 1
fi

curmap=$(xinput get-button-map $devid)
curmap=$(echo $curmap)
#echo "curmap=[$curmap]"

newmap=$(i=1; for j in $curmap; do
    case "$i.$j" in
    (2.2) echo 3  ;;
    (3.3) echo 2  ;;
    (*)   echo $j ;;
    esac
    i=$(($i + 1))
done)
newmap=$(echo $newmap)
#echo "newmap=[$newmap]"

[ "$curmap" != "$newmap" ] || exit 0

#set -x
exec xinput set-button-map $devid $newmap
