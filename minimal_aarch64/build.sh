#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

#https://lukaszgemborowski.github.io/articles/minimalistic-linux-system-on-qemu-arm.html

linux_url=https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-4.6.3.tar.xz
busybox_url=http://busybox.net/downloads/busybox-1.24.2.tar.bz2

archive_dir=$top_dir/archives
work_dir=$top_dir/work
  
ARCH=arm64
CROSS_COMPILE=aarch64-linux-gnu-

usage()
{
  echo "usage : $0 [OPTIONS] target1 target2 ..."
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
  #make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE versatile_defconfig
  make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE defconfig
  make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE
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
  make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE
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

run()
{
  qemu-system-aarch64 \
    -M virt \
    -cpu cortex-a53 \
	-kernel $work_dir/linux-4.6.3/arch/arm64/boot/Image \
	-initrd $work_dir/rootfs.cpio.gz \
	-nographic \
	-append "root=/dev/mem serial=ttyAMA0"
}

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
      break
      ;;
  esac

  shift
done

if [ $# -eq 0 ]; then
  usage
  exit 1
fi

for arg in "$@"; do
  LANG=C type $arg | grep 'function' > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    $arg
  else
    default_target $arg
  fi
done



