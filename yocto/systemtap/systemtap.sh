#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

machine="qemuarm64"
release="4.14.76-yocto-standard"

remote="192.168.7.2"

usage()
{
    cat - << EOS
usage : $0 [options] target1 target2 ...
target
  sysroot
EOS

}

help()
{
    usage
}


all()
{
	help
}

clean()
{
  rm -f stap_hello.ko
}

mclean()
{
  clean
  rm -rf ${top_dir}/work
}

extract_sysroot()
{
  set -e
  
  rpmdir=${top_dir}/../rocko/build/tmp/deploy/rpm
  rpmfile=${rpmdir}/${machine}/kernel-devsrc-1.0-r0.${machine}.rpm

  echo "extract $rpmfile"
  mkdir -p ${top_dir}/work/sysroot
  cd ${top_dir}/work/sysroot
  rpm2cpio $rpmfile | cpio -id
  cd ${top_dir}
}

prepare()
{
  extract_sysroot

  # suppress error, 'Kernel function symbol table missing'
  cd ${top_dir}/work/sysroot/usr/src/kernel/
  ln -sf System.map-${release} System.map
  cd ${top_dir}
    
  . /opt/poky/2.4.4/environment-setup-aarch64-poky-linux
  export LDFLAGS=""

  cd ${top_dir}/work/sysroot/usr/src/kernel
  make scripts
  make prepare
  cd $top_dir
}

compile()
{
  . /opt/poky/2.4.4/environment-setup-aarch64-poky-linux
  export LDFLAGS=""

  kernel_src=${top_dir}/work/sysroot/usr/src/kernel
  tmpdir=${top_dir}/tmp

  mkdir -p $tmpdir

  command stap -v \
    -a arm64 \
    -B CROSS_COMPILE=$CROSS_COMPILE \
    -r $kernel_src \
    --sysroot=${top_dir}/work/sysroot \
    -e 'probe begin { log ("hello " . k) exit () } global k="world" ' \
    -m stap_hello \
    --tmpdir=$tmpdir \
    -p 4
}

run()
{
  echo "send stap_hello.ko to remote"
  scp -q stap_hello.ko $remote:/home/root/
  
  echo "run staprun"
  ssh -y $remote staprun stap_hello.ko
}

args=""

while [ $# -ne 0 ]; do
  case "$1" in
    -c )
      shift
      opts="$opts -c $1"
      ;;
    -v )
      opts="$opts -v"
      ;;
	*)
      args="$args $1"
	  ;;
  esac
  shift
done

if [ -z "$args" ]; then
  usage
  exit
fi

for arg in $args ; do
	LANG=C type $arg | grep 'function' > /dev/null 2>&1
	if [ $? -eq 0 ]; then
		$arg
	else
	    default_target $arg
	fi
done

