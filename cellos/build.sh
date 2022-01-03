#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"

cd $top_dir

build_dir=$top_dir/_build

mkdir -p $build_dir

usage()
{
	echo "usage : $0 [options] target1 target2 ..."
	exit 0
}

all()
{
	config
	build
}

config()
{
	. ./powerpc-eabi-gcc.bashrc
	cd $build_dir
	cmake -G "Unix Makefiles" $top_dir
	cd $top_dir
}

build()
{
	. ./powerpc-eabi-gcc.bashrc
	cd $build_dir
	cmake --build . -- all
	cd $top_dir
}

kernel()
{
	config
	cd $build_dir
	rm -f CMakeCache.txt
	cmake --build . -- clean kernel
	cd $top_dir
}

driver()
{
	config
	cd $build_dir
	rm -f CMakeCache.txt
	cmake --build . -- clean driver
	cd $top_dir
}

cellos()
{
	config
	cd $build_dir
	rm -f CMakeCache.txt
	cmake --build . -- clean cellos
	cd $top_dir
}

bootrom()
{
	config
	cd $build_dir
	rm -f CMakeCache.txt
	cmake --build . -- clean bootrom
	cd $top_dir
}

startup()
{
	config
	cd $build_dir
	rm -f CMakeCache.txt
	cmake --build . -- clean startup
	cd $top_dir
}

run()
{
	cd $build_dir
	cmake --build . -- qemu
	cd $top_dir
}

clean()
{
	cd $build_dir
	cmake --build . -- clean
	cd $top_dir
}

mclean()
{
	rm -rf $build_dir
}



logfile=""

while getopts hvl: option
do
	case "$option" in
		h)
			usage;;
		v)
			verbose=1;;
		l)
			logfile=$OPTARG;;
		*)
			echo unknown option "$option";;
	esac
done

shift $(($OPTIND-1))

if [ "x$logfile" != "x" ]; then
	echo logfile is $logfile
fi

for target in "$@ $TARGETS" ; do
    #echo target is "$target"
	LANG=C type $target | grep function
	res=$?
	echo res is $res
	if [ "x$res" = "x0" ]; then
		$target
	else
		make $target
	fi
done

