#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

if [ ! -e ./config.bashrc ]; then
    echo "ERROR : no config.bashrc in $top_dir"
    echo "Please create $top_dir/config.bashrc"
    echo "and define work_dir variable."
    exit 1
fi

. ./config.bashrc

machine="qemuarm64"

#image=core-image-minimal
image=core-image-base
debugfs=core-image-base-${machine}-dbg.ext4

remote=192.168.7.2
    
disk1="./disk1.ext4"

tools="chrpath gawk makeinfo"
for tool in $tools; do
  which $tool > /dev/null 2>&1
  res=$?

  if [ "$res" != "0" ]; then
    echo "ERROR : need $tool"
    exit 1
  fi
done

release="4.14.76-yocto-standard"

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
    mkdir -p $work_dir
    cd $work_dir

    if [ ! -d meta-openembedded ]; then
        git clone \
            https://git.openembedded.org/meta-openembedded
    else
        echo skip to clone meta-openembedded
    fi

    if [ ! -d meta-virtualization ]; then
        git clone \
            https://git.yoctoproject.org/git/meta-virtualization
    else
        echo skip to clone meta-virtualization
    fi

    if [ ! -d meta-cloud-services ]; then
        git clone \
          https://git.yoctoproject.org/git/meta-cloud-services
    else
        echo skip to clone meta-cloud-services
    fi

    if [ ! -d poky ]; then
        git clone \
            https://git.yoctoproject.org/git/poky
    else
        echo skip to clone poky
    fi

    cd $top_dir
}

checkout()
{
    cd $work_dir
	branch="rocko"

    if [ ! -d meta-openembedded ]; then
        echo ERROR : no meta-openembedded directory
    else
        git -C meta-openembedded checkout $branch
    fi

    if [ ! -d meta-virtualization ]; then
        echo ERROR : no meta-virtualization directory
    else
        git -C meta-virtualization checkout $branch
    fi
    
    if [ ! -d meta-cloud-services ]; then
        echo ERROR : no meta-cloud-services directory
    else
     	git -C meta-cloud-services checkout $branch
    fi

    if [ ! -d poky ]; then
        echo ERROR : no poky directory
    else
        git -C poky checkout $branch
    fi

    cd $top_dir
}

ls()
{
  command ls -l $work_dir
}


config()
{
    cmd="rm -rf $work_dir/build/conf"
    echo $cmd
    $cmd

    cd $work_dir
    pwd
    OEROOT=$work_dir/poky . ./poky/oe-init-build-env

  cat - << EOS >> conf/bblayers.conf

BBLAYERS_append = " $work_dir/meta-openembedded/meta-oe"
BBLAYERS_append = " $work_dir/meta-openembedded/meta-python"
BBLAYERS_append = " $work_dir/meta-openembedded/meta-networking"
BBLAYERS_append = " $work_dir/meta-openembedded/meta-filesystems"
BBLAYERS_append = " $work_dir/meta-virtualization"
BBLAYERS_append = " $top_dir/meta-misc"

EOS
     
    sed -i.bak \
      -e 's|^#DL_DIR\s*?=\s*"${TOPDIR}/downloads"|DL_DIR ?= "/home/share/yocto/downloads"|' \
      conf/local.conf
    
  sed -i.bak \
    -e 's|^MACHINE\s*??=\s*"qemux86"|MACHINE ??= "qemuarm64"|' \
    conf/local.conf

  cat - << "EOS" >> conf/local.conf
#PREFERRED_VERSION_linux-yocto = "4.14.76"

EXTRA_IMAGE_FEATURES_append = " tools-profile"
EXTRA_IMAGE_FEATURES_append = " tools-debug"
#EXTRA_IMAGE_FEATURES_append = " dbg-pkgs"
PACKAGE_DEBUG_SPLIT_STYLE   = "debug-file-directory"

TOOLCHAIN_TARGET_TASK_append = " kernel-devsrc"

#40 Gbytes of extra space with the line:
#IMAGE_ROOTFS_EXTRA_SPACE = "41943040"

# 16 Gbytes of extra space (1024*1024*16)
IMAGE_ROOTFS_EXTRA_SPACE = "16777216"


DISTRO_FEATURES_append = " virtualization"

KERNEL_EXTRA_FEATURES_append = " lxc.scc"
KERNEL_EXTRA_FEATURES_append = " docker.scc"

# LXC
IMAGE_INSTALL_append = " lxc cgroup-lite"
IMAGE_INSTALL_append = " dropbear"
IMAGE_INSTALL_append = " gnupg"
IMAGE_INSTALL_append = " nfs-utils"

# Docker
IMAGE_INSTALL_append = " docker"
IMAGE_INSTALL_append = " docker-contrib"

CORE_IMAGE_EXTRA_INSTALL_append = " kernel-modules"
CORE_IMAGE_EXTRA_INSTALL_append = " python-core python-pip"

# systemd
DISTRO_FEATURES_append = " systemd"
VIRTUAL-RUNTIME_init_manager = "systemd"
VIRTUAL-RUNTIME_initscripts = "systemd-compat-units"

SERIAL_CONSOLES_CHECK = "${SERIAL_CONSOLES}"

IMAGE_FEATURES += " package-management"
PACKAGE_CLASSES ?= " package_rpm"

IMAGE_INSTALL_append = " stress"
IMAGE_INSTALL_append = " htop"

IMAGE_INSTALL_append = " python3-pip"
IMAGE_INSTALL_append = " python3-flask"
IMAGE_INSTALL_append = " fio"
IMAGE_INSTALL_append = " iperf3"
IMAGE_INSTALL_append = " gdb"

IMAGE_INSTALL_append = " e2fsprogs"

IMAGE_INSTALL_append = " oprofile"
IMAGE_INSTALL_append = " strace"
IMAGE_INSTALL_append = " valgrind"

IMAGE_INSTALL_append = " systemtap"
IMAGE_INSTALL_append = " make"
IMAGE_INSTALL_append = " packagegroup-core-buildessential"
IMAGE_INSTALL_append = " coreutils"
IMAGE_INSTALL_append = " kernel-devsrc"

IMAGE_GEN_DEBUGFS = "1"
IMAGE_FSTYPES_DEBUGFS = "tar.bz2"
#USER_CLASSES += "image-combined-dbg"

# enables kernel debug symbols
KERNEL_EXTRA_FEATURES_append = " features/debug/debug-kernel.scc"

# minimal, just run-time systemtap configuration in target image
#PACKAGECONFIG_pn-systemtap = "monitor"

EOS

  pwd
  cd $top_dir
}

image()
{
    cd $work_dir
    OEROOT=$work_dir/poky . ./poky/oe-init-build-env
    cmd="bitbake $image"
    echo $cmd
    $cmd
    cd $top_dir
}

disk()
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
    cd $work_dir

    params="-m 4096"
    params="$params -smp 4"

    OEROOT=$work_dir/poky . ./poky/oe-init-build-env

    params="$params -device virtio-blk-device,drive=disk1"
    params="$params -drive id=disk1,file=$disk1,if=none,format=raw"

    bootparams=""
    bootparams="$bootparams root=/dev/vdb"

	disk

    runqemu nographic qemuarm64 \
      qemuparams="$params" bootparams="$bootparams" \
      $image
    cd $top_dir
}

show_images()
{
    cd $work_dir
    OEROOT=$work_dir/poky . ./poky/oe-init-build-env
    bitbake-layers show-recipes | grep 'core-image-'
    cd $top_dir
}

show_recipes()
{
    cd $work_dir
    OEROOT=$work_dir/poky . ./poky/oe-init-build-env
    bitbake-layers show-recipes
    cd $top_dir
}

show_layers()
{
    cd $work_dir
    OEROOT=$work_dir/poky . ./poky/oe-init-build-env
    bitbake-layers show-layers
    cd $top_dir
}

info()
{
    echo "top_dir   : $top_dir"
    echo "work_dir : $work_dir"
    echo "image     : $image"
}

clean()
{
    :
}

mclean()
{
  :
}

image()
{
    cd $work_dir
    OEROOT=$work_dir/poky . ./poky/oe-init-build-env
    bitbake $opts $image
    cd $top_dir
}


sdk()
{
    cd $work_dir
    OEROOT=$work_dir/poky . ./poky/oe-init-build-env
    bitbake -c populate_sdk $image
    cd $top_dir
}

sdk_ext()
{
    cd $work_dir
    OEROOT=$work_dir/poky . ./poky/oe-init-build-env
    bitbake -c populate_sdk_ext $image
    cd $top_dir

	# install extensible sdk
	# $ sh tmp/deploy/sdk/poky-glibc-x86_64-core-image-base-aarch64-toolchain-ext-2.4.4.sh

    # $ source ~/poky_sdk/environment-setup-aarch64-poky-linux
	# $ devtool build-image core-image-minimal

	# run qemu using devtool (escape white space!)
	# $ devtool runqemu nographic qemuparams="-m\ 4096" qemuparams="-smp\ 4" core-image-minimal

}

default_target()
{
  arg=$1
  # must remove all argument before calling oe-init-build-env
  while [ $# -ne 0 ]; do
    shift
  done
  
  cd $work_dir

  OEROOT=$work_dir/poky . ./poky/oe-init-build-env
  bitbake_cmd="bitbake $opts $arg"
  echo $bitbake_cmd
  $bitbake_cmd
  cd $top_dir
}

debug()
{
  cd $work_dir
  OEROOT=$work_dir/poky . ./poky/oe-init-build-env
  which crosstap
  #crosstap \
  #  -i "core-image-base" \
  #  -m "test_cross" \
  #  test_hello.stp
  echo "debugfs is $debugfs"
  pwd
  #ls -l $work_dir/build
  ls build
  cd $top_dir
}


sysroot()
{
  set -e
  rm -rf ./sysroot
  rm -f stap_hello.ko
  
  #rpmdir=$top_dir/rocko/build/tmp/deploy/rpm/qemuarm64
  rpmdir=$top_dir/rocko/build/tmp/deploy/rpm

  if [ ! -e "sysroot/usr/src/kernel/Makefile" ]; then
    mkdir -p sysroot
    echo "mkdir sysroot"
    cd sysroot
      rpmfiles=`find $rpmdir -name "kernel-dev*.rpm"`
      for rpmfile in $rpmfiles; do
        echo "extract $rpmfile"
        rpm2cpio $rpmfile | cpio -id
      done
      
      rpmfiles=`find $rpmdir -name "systemtap-3.1-*.rpm"`
      for rpmfile in $rpmfiles; do
        echo "extract $rpmfile"
        rpm2cpio $rpmfile | cpio -id
      done
    cd $top_dir

    # suppress error, 'Kernel function symbol table missing'
    cd sysroot/usr/src/kernel/
    ln -sf System.map-${release} System.map
    cd $top_dir
  else
    echo "skip rpm2cpio"
  fi

  cd sysroot/usr/src/kernel
    . /opt/poky/2.4.4/environment-setup-aarch64-poky-linux
    export LDFLAGS=""
    make scripts
    make prepare
  cd $top_dir
}

stap()
{
  . /opt/poky/2.4.4/environment-setup-aarch64-poky-linux
  #. /opt/poky/2.4.4/environment-setup-x86_64-pokysdk-linux

  export LDFLAGS=""

  kernel_src=$top_dir/sysroot/usr/src/kernel
  tmpdir=$top_dir/tmp

  mkdir -p $tmpdir

  #stap=`which stap`
  #stap=`pwd`/rocko/build/tmp/work/x86_64-linux/systemtap-native/3.1-r0/image/home/kojiro/devel/qemu_samples/yocto/rocko/build/tmp/work/x86_64-linux/systemtap-native/3.1-r0/recipe-sysroot-native/usr/bin/stap

  command stap -v -a arm64 -B CROSS_COMPILE=$CROSS_COMPILE \
    -r $kernel_src \
    --sysroot=$top_dir/sysroot \
    -e 'probe begin { log ("hello " . k) exit () } global k="world" ' \
    -m stap_hello \
    --tmpdir=$tmpdir \
    -p 4

  echo "send stap_hello.ko to remote"
  scp -q stap_hello.ko $remote:/home/root/
  echo "run staprun"
  cat - << 'EOS' | ssh -y $remote sh -s
  {
    staprun stap_hello.ko
    rm -f stap_hello.ko
  }
EOS

}

repo()
{
  createrepo $work_dir/build/tmp/deploy/rpm
}

vars()
{
  cd $work_dir
  OEROOT=$work_dir/poky . ./poky/oe-init-build-env
  bitbake -e
  cd $top_dir

}

cmd=""
verbose=""
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
	LANG=C type $arg | grep 'function' > /dev/null 2>&1
	if [ $? -eq 0 ]; then
		$arg
	else
	    default_target $arg
	fi
done

