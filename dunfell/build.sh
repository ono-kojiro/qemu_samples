#!/bin/sh

set -e

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

work_dir="${top_dir}/work"
src_dir="${top_dir}/sources"

mkdir -p $work_dir $src_dir

url_oe="https://git.openembedded.org/meta-openembedded"
url_meta_virt="https://git.yoctoproject.org/git/meta-virtualization"
url_poky="https://git.yoctoproject.org/git/poky"

machine="qemuarm64"

image=core-image-minimal

remote=192.168.7.2

sysroot="${work_dir}/sysroot"
    
disk1="${top_dir}/disk1.ext4"

tools="chrpath gawk makeinfo"
for tool in $tools; do
  which $tool > /dev/null 2>&1
  res=$?

  if [ "$res" != "0" ]; then
    echo "ERROR : need $tool"
    exit 1
  fi
done

codename="dunfell"
release="4.12.28-yocto-standard"

help()
{
    usage
}

usage()
{
	echo "usage : $0 [options] target1 target2 ..."
    echo ""
    echo "  target"
    echo "    clone, checkout, config, build"
    echo "    run"
    echo "    clean, mclean"
    echo "    show_layers, show_recipes, show_images"
    echo ""
    echo "  variables"
    echo "    work_dir   $work_dir"
	exit 0
}

all()
{
	help
}
        
clone()
{
    mkdir -p $src_dir
    cd $src_dir

    if [ ! -d meta-openembedded ]; then
        git clone $url_oe
    else
        echo skip to clone meta-openembedded
    fi

    if [ ! -d meta-virtualization ]; then
        git clone $url_meta_virt
    else
        echo skip to clone meta-virtualization
    fi

    if [ ! -d poky ]; then
        git clone $url_poky
    else
        echo skip to clone poky
    fi

    cd $top_dir
}

checkout()
{
    cd ${src_dir}
    pwd

    if [ ! -d meta-openembedded ]; then
        echo ERROR : no meta-openembedded directory
    else
        git -C meta-openembedded checkout $codename
    fi

    if [ ! -d meta-virtualization ]; then
        echo ERROR : no meta-virtualization directory
    else
        git -C meta-virtualization checkout $codename
    fi
    
    if [ ! -d poky ]; then
        echo ERROR : no poky directory
    else
        git -C poky checkout $codename
    fi

    cd $top_dir
}

config()
{
    cmd="rm -rf $work_dir/build/conf"
    echo $cmd
    $cmd

    mkdir -p $work_dir
    cd ${src_dir}/poky
    BDIR=${work_dir}/build . ./oe-init-build-env

  cat - << EOS >> conf/bblayers.conf
BBLAYERS_append = " $src_dir/meta-openembedded/meta-oe"
BBLAYERS_append = " $src_dir/meta-openembedded/meta-python"
BBLAYERS_append = " $src_dir/meta-openembedded/meta-networking"
BBLAYERS_append = " $src_dir/meta-openembedded/meta-filesystems"
BBLAYERS_append = " $src_dir/meta-virtualization"
#BBLAYERS_append = " $top_dir/meta-misc"

EOS
     
    sed -i.bak \
      -e 's|^#DL_DIR\s*?=\s*"${TOPDIR}/downloads"|DL_DIR ?= "/home/share/yocto/downloads"|' \
      conf/local.conf
    
  sed -i.bak \
    -e 's|^MACHINE\s*??=\s*"qemux86-64"|MACHINE ??= "qemuarm64"|' \
    conf/local.conf

  cat - << "EOS" >> conf/local.conf
# 4GB of extra space (1024*1024*4)
IMAGE_ROOTFS_EXTRA_SPACE = "4194304"

# systemd
DISTRO_FEATURES_append = " systemd"
VIRTUAL-RUNTIME_init_manager = "systemd"
VIRTUAL-RUNTIME_initscripts = "systemd-compat-units"

# ssh
IMAGE_FEATURES_append = " ssh-server-openssh"
IMAGE_INSTALL_append = " openssh openssh-sftp-server"

IMAGE_FEATURES_append = " package-management"
PACKAGE_CLASSES ?= " package_rpm"

# LXC, Docker
DISTRO_FEATURES_append = " virtualization"
KERNEL_EXTRA_FEATURES_append = " lxc.scc"
KERNEL_EXTRA_FEATURES_append = " docker.scc"

# enables kernel debug symbols
KERNEL_EXTRA_FEATURES_append = " features/debug/debug-kernel.scc"
PACKAGE_DEBUG_SPLIT_STYLE   = "debug-file-directory"

EOS
  cd $top_dir
}

image()
{
  cd ${src_dir}/poky
  BDIR=${work_dir}/build . ./oe-init-build-env
  cmd="bitbake $opts ${image}"
  echo $cmd
  $cmd
  cd ${top_dir}
}

build()
{
  image
}

make_disk()
{
  if [ ! -e "$disk1" ]; then
    cmd="dd if=/dev/zero of=$disk1 bs=1024K count=65536"
    echo $cmd
    $cmd
  else
    echo "skip $disk1"
  fi
}

run()
{
  cd ${src_dir}/poky
  BDIR=${work_dir}/build . ./oe-init-build-env
  
  params="-m 4096"
  params="$params -smp 4"

  params="$params -device virtio-blk-device,drive=disk1"
  params="$params -drive id=disk1,file=$disk1,if=none,format=raw"

  bootparams=""
  bootparams="$bootparams root=/dev/vdb"

  make_disk

  runqemu nographic ${machine} \
    qemuparams="$params" bootparams="$bootparams" \
    $image
  cd $top_dir
}

clean()
{
    :
}

mclean()
{
  :
}

sdk()
{
  cd ${src_dir}/poky
  BDIR=${work_dir}/build . ./oe-init-build-env
  bitbake -c populate_sdk $image
  cd ${top_dir}
}

esdk()
{
  cd ${src_dir}/poky
  BDIR=${work_dir}/build . ./oe-init-build-env
  bitbake -c populate_sdk_ext $image
  cd ${top_dir}
}

default_target()
{
  arg=$1; shift
  
  cd ${src_dir}/poky
  BDIR=${work_dir}/build . ./oe-init-build-env
  bitbake $arg
  cd ${top_dir}
}

opts=""
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
  echo "check $arg"
  LANG=C type $arg | grep 'function'
  if [ $? -eq 0 ]; then
    $arg
  else
    default_target $arg
  fi
done

