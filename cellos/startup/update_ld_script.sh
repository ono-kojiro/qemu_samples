#!/bin/sh

while getopts o: OPT; do
	case $OPT in
		o) OUTPUT=$OPTARG ;;
		*) exit 1;; # invalid option, or no argument
	esac
done
shift $((OPTIND - 1))

#argv=("$@")
#argc=$#

echo OUTPUT is $OUTPUT

OBJECT=`find ./CMakeFiles/ -name "*.S.obj"`
echo $OBJECT

for INPUT in "$@"; do
	echo input is $INPUT
	cat $INPUT | \
		sed -e "s|@CELLSTARTUP_OBJ@|$OBJECT|" > \
		$OUTPUT
done

