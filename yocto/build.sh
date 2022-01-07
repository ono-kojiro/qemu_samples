#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

if [ ! -e ./config.bashrc ]; then
    echo "ERROR : no config.bashrc in $top_dir"
    echo "Please create $top_dir/config.bashrc"
    echo "and define build_dir variable."
    exit 1
fi

. ./config.bashrc

#image=core-image-minimal
image=core-image-base
    
disk1="$build_dir/disk1.ext4"

tools="chrpath gawk makeinfo"
for tool in $tools; do
  which $tool > /dev/null 2>&1
  res=$?

  if [ "$res" != "0" ]; then
    echo "ERROR : need $tool"
    exit 1
  fi
done

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
    echo "    build_dir   $build_dir"
	exit 0
}

all()
{
	help
}
        
clone()
{
    mkdir -p $build_dir
    cd $build_dir

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
    cd $build_dir

    if [ ! -d meta-openembedded ]; then
        echo ERROR : no meta-openembedded directory
    else
        git -C meta-openembedded checkout rocko
    fi

    if [ ! -d meta-virtualization ]; then
        echo ERROR : no meta-virtualization directory
    else
        git -C meta-virtualization checkout rocko
    fi
    
    if [ ! -d meta-cloud-services ]; then
        echo ERROR : no meta-cloud-services directory
    else
	git -C meta-cloud-services checkout rocko
    fi

    if [ ! -d poky ]; then
        echo ERROR : no poky directory
    else
        git -C poky checkout rocko
    fi

    cd $top_dir
}

ls()
{
  command ls -l $build_dir
}


config()
{
    mkdir -p $build_dir
    cd $build_dir

    cd poky
    echo removing build/conf...
    rm -rf build/conf
    echo done.
    . ./oe-init-build-env

    {
      echo ""
      echo "BBLAYERS_append = \" ../../meta-openembedded/meta-oe\""
      echo "BBLAYERS_append = \" ../../meta-openembedded/meta-python\""
      echo "BBLAYERS_append = \" ../../meta-openembedded/meta-networking\""
      echo "BBLAYERS_append = \" ../../meta-openembedded/meta-filesystems\""
      echo "BBLAYERS_append = \" ../../meta-virtualization\""
      echo "BBLAYERS_append = \" $top_dir/meta-misc\""
      echo ""
    } >> conf/bblayers.conf
     
    sed -i.bak \
      -e 's|^#DL_DIR\s*?=\s*"${TOPDIR}/downloads"|DL_DIR ?= "/home/share/yocto/downloads"|' \
      conf/local.conf
    
  sed -i.bak \
    -e 's|^MACHINE\s*??=\s*"qemux86"|MACHINE ??= "qemuarm64"|' \
    conf/local.conf

  cat - << "EOS" >> conf/local.conf
EXTRA_IMAGE_FEATURES_append = " tools-profile"

#40 Gbytes of extra space with the line:
IMAGE_ROOTFS_EXTRA_SPACE = "41943040"

DISTRO_FEATURES_append = " virtualization"

# LXC
IMAGE_INSTALL_append = " lxc cgroup-lite"
IMAGE_INSTALL_append = " dropbear"
IMAGE_INSTALL_append = " gnupg"
IMAGE_INSTALL_append = " nfs-utils"

# Docker
IMAGE_INSTALL_append = " docker"
IMAGE_INSTALL_append = " docker-contrib"

CORE_IMAGE_EXTRA_INSTALL_append = " kernel-modules"

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
EOS

  cd $top_dir
}

build()
{
    cd $build_dir/poky
    . ./oe-init-build-env
    bitbake $image
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
    cd $build_dir/poky/

    params="-m 4096"
    params="$params -smp 4"

    . ./oe-init-build-env

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
    cd $build_dir/poky
    . ./oe-init-build-env > /dev/null 2>&1
    bitbake-layers show-recipes | grep 'core-image-'
    cd $top_dir
}

show_recipes()
{
    cd $build_dir/poky
    . ./oe-init-build-env > /dev/null 2>&1
    bitbake-layers show-recipes
    cd $top_dir
}

show_layers()
{
    cd $build_dir/poky
    . ./oe-init-build-env > /dev/null 2>&1
    bitbake-layers show-layers
    cd $top_dir
}

info()
{
    echo "top_dir   : $top_dir"
    echo "build_dir : $build_dir"
    echo "image     : $image"
}

clean()
{
    :
}

mclean()
{
	rm -rf $build_dir/poky/build
}

sdk()
{
    cd $build_dir/poky
    . ./oe-init-build-env > /dev/null 2>&1
    bitbake -c populate_sdk $image
    cd $top_dir

	echo "generated installer:"
	echo poky/build/tmp/deploy/sdk/poky-glibc-x86_64-core-image-base-aarch64-toolchain-2.4.4.sh
}

sdk_ext()
{
    cd $build_dir/poky
    . ./oe-init-build-env > /dev/null 2>&1
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
  echo "default_target called"
  target=$1

  while [ "$#" -ne 0 ]; do
    shift
  done
    
  cd $build_dir/poky
  . ./oe-init-build-env > /dev/null 2>&1
  env | sort
  pwd
  cmd="bitbake -c $cmd $target"
  echo $cmd
  $cmd
  cd $top_dir
}

cmd=""

while [ "$#" -ne 0 ]; do
  case "$1" in
    -h | --help)
      ;;
	-v | --version)
	  ;;
	-l | --logfile)
      shift	
	  logfile=$1
	  ;;
    -c | --command)
	  shift
	  cmd=$1
	  ;;
	*)
	  break
	  ;;
  esac

  shift

done


if [ "x$@" = "x" ]; then
  usage
  exit
fi

for target in "$@" ; do
	LANG=C type $target | grep function > /dev/null 2>&1
	if [ "$?" -eq 0 ]; then
		$target
	else
	    default_target $target
	fi
done
