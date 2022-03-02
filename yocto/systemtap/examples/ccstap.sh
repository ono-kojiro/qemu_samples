#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

if [ $# -eq 0 ]; then
  echo "usage : $0 <FILE.stp>"
  exit 1
fi

input_stp=$1
remote="192.168.7.2"

. /opt/poky/2.4.4/environment-setup-aarch64-poky-linux
export LDFLAGS=""

module_name=`basename $input_stp .stp`

# must set absolute path!!!
sysroot="$top_dir/../work/sysroot"
kernel_src="$sysroot/usr/src/kernel"
tmpdir=$top_dir/tmp

mkdir -p $tmpdir

stap -v \
  -a arm64 \
  -B CROSS_COMPILE=$CROSS_COMPILE \
  --sysroot=$sysroot \
  -r $kernel_src \
  -m $module_name \
  --tmpdir=$tmpdir \
  -p 4 \
  $input_stp

scp -q ${module_name}.ko $remote:/home/root/

ssh -y $remote staprun ${module_name}.ko


