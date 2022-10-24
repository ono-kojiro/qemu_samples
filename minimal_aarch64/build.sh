#!/usr/bin/env sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

#https://lukaszgemborowski.github.io/articles/minimalistic-linux-system-on-qemu-arm.html

#linux_url=https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.4.177.tar.xz
#linux_url=http://ftp.jaist.ac.jp/pub/Linux/kernel.org/linux/kernel/v5.x/linux-5.4.167.tar.xz
#linux_url=http://ftp.jaist.ac.jp/pub/Linux/kernel.org/linux/kernel/v5.x/linux-5.10.149.tar.xz
linux_url=http://ftp.jaist.ac.jp/pub/Linux/kernel.org/linux/kernel/v5.x/linux-5.15.74.tar.xz

#busybox_url=https://busybox.net/downloads/busybox-1.34.1.tar.bz2
busybox_url=https://busybox.net/downloads/busybox-1.35.0.tar.bz2

archive_dir=$top_dir/archives
work_dir=$top_dir/work
  
ARCH=arm64
CROSS_COMPILE=aarch64-linux-gnu-

ret=0

tool_list="flex bison ${CROSS_COMPILE}gcc"

for tool_name in $tool_list; do
  which $tool_name
  if [ $? -ne 0 ]; then
    echo "ERROR : no $tool_name"
    ret=`expr "$ret" + 1`
  fi
done

if [ "$ret" -ne 0 ]; then
  exit $ret
fi

echo "tool check finished"

usage()
{
  cat - << EOS
usage : $0 [OPTIONS] target1 target2 ...
target
  linux, busybox, rootfs
  run
EOS

}

help()
{
  usage
}

linux()
{
  mkdir -p $archive_dir
  archive=`basename $linux_url`
  dirname=`basename -s .tar.xz $archive`

  echo archive is $archive
  if [ ! -e "./archives/$archive" ]; then
    curl -o ./archives/$archive $linux_url
  else
    echo "skip download $archive"
  fi

  mkdir -p $work_dir
  cd $work_dir
  if [ ! -d "$dirname" ]; then
    echo "extract $archive"
    tar xf $archive_dir/$archive
  else
    echo "skip extract $dirname"
  fi

  cd $dirname
  make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE defconfig
  make -j8 ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE
  cd $top_dir
}

menuconfig()
{
  linux_dir=`basename -s .tar.xz $linux_url`
  cd $work_dir/$linux_dir
  make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE menuconfig
  cd $top_dir
}


busybox()
{
  mkdir -p $archive_dir
  url=$busybox_url
  archive=`basename $url`
  dirname=`basename -s .tar.bz2 $archive`

  echo archive is $archive
  if [ ! -e "./archives/$archive" ]; then
    curl -o ./archives/$archive $url
  else
    echo "skip download $archive"
  fi

  mkdir -p $work_dir
  cd $work_dir
  if [ ! -d "$dirname" ]; then
    echo "extract $archive"
    tar xf $archive_dir/$archive
  else
    echo "skip extract $dirname"
  fi

  cd $dirname
  make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE defconfig
  sed -i.bak -e 's|# CONFIG_STATIC is not set|CONFIG_STATIC=y|' .config
  make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE -j7
  make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE install

  cd $top_dir
}

rootfs()
{
  cd $work_dir
  
  busybox_dir=`basename -s .tar.bz2 $busybox_url`

  rm -rf rootfs
  mkdir -p rootfs
  cat - << 'EOS' > rootfs/init
#!/bin/sh

mount -t proc none /proc
mount -t sysfs none /sys
mknod -m 660 /dev/mem c 1 1

echo -e "\nHello!\n"

exec /bin/sh
EOS

  chmod +x rootfs/init
  cp -av $work_dir/$busybox_dir/_install/* rootfs/
  mkdir -pv rootfs/bin
  mkdir -pv rootfs/sbin
  mkdir -pv rootfs/etc
  mkdir -pv rootfs/proc
  mkdir -pv rootfs/sys
  mkdir -pv rootfs/usr/bin
  mkdir -pv rootfs/usr/sbin
 
  image=$work_dir/rootfs.cpio.gz
  cd rootfs
  find . -print0 | cpio --null -ov --format=newc | gzip -9 > $image
  cd $top_dir
}

disk()
{
  rm -f rootfs.ext4
  dd if=/dev/zero of=rootfs.ext4 seek=202550 count=0 bs=1024
  mkfs.ext4 -F -i 4096 rootfs.ext4 -d work/rootfs
  fsck.ext4 -pvfD rootfs.ext4

  rm -f ./disk1.ext4
  mke2fs -L '' -N 0 -t ext4 ./disk1.ext4 32M
}

run()
{
  linux_dir=`basename -s .tar.xz $linux_url`
  
  qemu-system-aarch64 \
    -M virt \
    -cpu cortex-a53 \
	-kernel $work_dir/$linux_dir/arch/arm64/boot/Image \
	-initrd $work_dir/rootfs.cpio.gz \
    -drive id=disk1,file=./disk1.ext4,if=none,format=raw \
    -device virtio-blk-device,drive=disk1 \
	-nographic \
	-append "root=/dev/mem serial=ttyAMA0"
}

run2()
{
  linux_dir=`basename -s .tar.xz $linux_url`
  
  qemu-system-aarch64 \
    -M virt \
    -cpu cortex-a53 \
	-kernel $work_dir/$linux_dir/arch/arm64/boot/Image \
    -drive id=disk1,file=./rootfs.ext4,if=none,format=raw \
    -device virtio-blk-device,drive=disk1 \
	-nographic \
	-append "root=/dev/vda serial=ttyAMA0"
}

args=""

while [ $# -ne 0 ]; do
  case $1 in
    -h | --help)
      usage
      exit 1
      ;;
    -v | --version)
      usage
      exit 1
      ;;
    *)
      args="$args $1"
      ;;
  esac

  shift
done

if [ -z "$args" ]; then
  usage
  exit 1
fi

for arg in $args; do
  echo "check $arg ..."
  num=`LANG=C type $arg | grep 'function' | wc -l`
  if [ $num -ne 0 ]; then
    $arg
  else
    default_target $arg
  fi
done



