#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

work_dir="${top_dir}/work"
src_dir="/home/share/yocto/dunfell/sources"
branch="dunfell"

machine="qemuarm64"

image=core-image-minimal

remote=192.168.7.2

sysroot="${work_dir}/sysroot"
    
disk1="${top_dir}/disk1.ext4"

release="4.12.28-yocto-standard"
    
urls="
 https://git.openembedded.org/meta-openembedded
 https://git.yoctoproject.org/git/meta-virtualization
 https://git.yoctoproject.org/git/meta-cloud-services
 https://git.yoctoproject.org/git/poky
"

layers=""
for url in $urls; do
  layers="$layers $(basename $url)"
done

check_tool()
{
  tools="chrpath gawk makeinfo gcc make python diffstat"
  for tool in $tools; do
    which $tool > /dev/null 2>&1
    res=$?

    if [ "$res" != "0" ]; then
      echo "ERROR : need $tool"
      exit 1
    else
      echo "INFO : found $tool"
    fi
  done
}

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

prepare()
{
  tools="chrpath gawk texinfo gcc g++ make python-minimal diffstat"
  sudo apt -y install $tools
}

all()
{
	help
}

create_layer()
{
  cd ${src_dir}/poky
  BDIR=${work_dir}/build . ./oe-init-build-env
  cd ${work_dir}/build

  cd ${top_dir}
  bitbake-layers create-layer meta-mylayer
}

add_layer()
{
  cd ${src_dir}/poky
  BDIR=${work_dir}/build . ./oe-init-build-env
  cd ${work_dir}/build
  bitbake-layers add-layer ../../meta-mylayer
}


create_recipe()
{
  #meta-mylayer/recipes-example/example/example_0.1.bb
  rm -rf   meta-mylayer/recipes-mycategory/myapp
  mkdir -p meta-mylayer/recipes-mycategory/myapp
  cp -f myapp_0.0.1.bb meta-mylayer/recipes-mycategory/myapp/
}
        
clone()
{
  mkdir -p $src_dir
  cd $src_dir

  for url in $urls; do
    dirname=$(basename $url)
    if [ ! -d "$dirname" ]; then
      git clone $url
    else
      echo "skip to clone $url"
    fi
  done

  cd $top_dir
}

update()
{
    cd ${src_dir}
    for layer in $layers; do
      if [ ! -d "$layer" ]; then
        echo ERROR : no $layer directory
      else
        echo "update $layer ..."
        git -C $layer pull
      fi
    done
    cd $top_dir
}

config()
{
    cmd="rm -rf $work_dir/build/conf"
    echo $cmd
    $cmd

    mkdir -p $work_dir
    cd $work_dir
    pwd

    cd ${src_dir}/poky
    #OEROOT=${src_dir}/poky . ${src_dir}/poky/oe-init-build-env
    pwd
    BDIR=${work_dir}/build \
    . ./oe-init-build-env

    cd $work_dir/build

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
EXTRA_IMAGE_FEATURES_append = " dbg-pkgs"
EXTRA_IMAGE_FEATURES_append = " tools-profile"

PACKAGE_DEBUG_SPLIT_STYLE   = "debug-file-directory"
#TOOLCHAIN_TARGET_TASK_append = " kernel-devsrc"

# 4GB of extra space (1024*1024*4)
IMAGE_ROOTFS_EXTRA_SPACE = "4194304"

# enable virtualization for docker and lxc
DISTRO_FEATURES_append = " virtualization"

# systemd
DISTRO_FEATURES_append = " systemd"
VIRTUAL-RUNTIME_init_manager = "systemd"
VIRTUAL-RUNTIME_initscripts = "systemd-compat-units"

SERIAL_CONSOLES_CHECK = "${SERIAL_CONSOLES}"

IMAGE_FEATURES += " package-management"
PACKAGE_CLASSES ?= " package_rpm"

IMAGE_INSTALL_append = " dropbear"


IMAGE_INSTALL_append = " systemtap"
#IMAGE_INSTALL_append = " packagegroup-core-buildessential"
IMAGE_INSTALL_append = " coreutils"

#IMAGE_INSTALL_append = " lxc cgroup-lite"
#IMAGE_INSTALL_append = " docker docker-contrib"
#IMAGE_INSTALL_append = " docker-ce"

IMAGE_GEN_DEBUGFS = "1"
IMAGE_FSTYPES = "ext4 tar.bz2"
IMAGE_FSTYPES_DEBUGFS = "tar.bz2"
#USER_CLASSES += "image-combined-dbg"

# enables kernel debug symbols
KERNEL_EXTRA_FEATURES_append = " features/debug/debug-kernel.scc"

# minimal, just run-time systemtap configuration in target image
#PACKAGECONFIG_pn-systemtap = "monitor"

CORE_IMAGE_EXTRA_INSTALL_append = " kernel-modules"

EOS
  cd $top_dir
}

image()
{
  cd ${src_dir}/poky
  BDIR=${work_dir}/build . ./oe-init-build-env

  cd $work_dir/build
  cmd="bitbake $opts ${image}"
  echo $cmd
  $cmd
  cd ${top_dir}
}

default_target()
{
  target=$1
  shift

  cd ${src_dir}/poky
  BDIR=${work_dir}/build . ./oe-init-build-env

  cd $work_dir/build
  cmd="bitbake $opts ${target}"
  echo $cmd
  $cmd
  cd ${top_dir}
}


build()
{
  image
}

disk()
{
  if [ ! -e "$disk1" ]; then
    #cmd="dd if=/dev/zero of=$disk1 bs=1024K count=65536"
    cmd="dd if=/dev/zero of=$disk1 bs=1024K count=4096"
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
  cd $work_dir/build
  
  params="-m 4096"
  params="$params -smp 4"

  params="$params -device virtio-blk-device,drive=disk1"
  params="$params -drive id=disk1,file=$disk1,if=none,format=raw"

  bootparams=""
  bootparams="$bootparams root=/dev/vdb"

  disk

  runqemu nographic slirp ${machine} \
    qemuparams="$params" bootparams="$bootparams" \
    $image
  cd $top_dir
}

show_images()
{
  cd ${src_dir}/poky
  BDIR=${work_dir}/build . ./oe-init-build-env
  cd $work_dir/build

  bitbake-layers show-recipes | grep 'core-image-'
  
  cd ${top_dir}
}

show_recipes()
{
  cd ${src_dir}/poky
  BDIR=${work_dir}/build . ./oe-init-build-env
  cd $work_dir/build
  
  bitbake-layers show-recipes
  
  cd ${top_dir}
}

show_layers()
{
  cd $work_dir
  OEROOT=$work_dir/poky . ./poky/oe-init-build-env
  bitbake-layers show-layers
  cd ${top_dir}
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

sdk()
{
  cd ${work_dir}
  OEROOT=${src_dir}/poky . ${src_dir}/poky/oe-init-build-env
  cmd="bitbake -c populate_sdk ${image}"
  echo $cmd
  $cmd
  cd ${top_dir}
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

