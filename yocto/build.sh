#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

work_dir="${top_dir}/work"
src_dir="${top_dir}/rocko"

machine="qemuarm64"

#image=core-image-minimal
image=core-image-base

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

config()
{
    cmd="rm -rf $work_dir/build/conf"
    echo $cmd
    $cmd

    mkdir -p $work_dir
    cd $work_dir
    pwd
    OEROOT=${src_dir}/poky . ${src_dir}/poky/oe-init-build-env

  cat - << EOS >> conf/bblayers.conf
BBLAYERS_append = " $src_dir/meta-openembedded/meta-oe"
BBLAYERS_append = " $src_dir/meta-openembedded/meta-python"
BBLAYERS_append = " $src_dir/meta-openembedded/meta-networking"
BBLAYERS_append = " $src_dir/meta-openembedded/meta-filesystems"
BBLAYERS_append = " $src_dir/meta-virtualization"
BBLAYERS_append = " $top_dir/meta-misc"

EOS
     
    sed -i.bak \
      -e 's|^#DL_DIR\s*?=\s*"${TOPDIR}/downloads"|DL_DIR ?= "/home/share/yocto/downloads"|' \
      conf/local.conf
    
  sed -i.bak \
    -e 's|^MACHINE\s*??=\s*"qemux86"|MACHINE ??= "qemuarm64"|' \
    conf/local.conf

  cat - << "EOS" >> conf/local.conf
EXTRA_IMAGE_FEATURES_append = " dbg-pkgs"
PACKAGE_DEBUG_SPLIT_STYLE   = "debug-file-directory"
TOOLCHAIN_TARGET_TASK_append = " kernel-devsrc"

# 4GB of extra space (1024*1024*4)
IMAGE_ROOTFS_EXTRA_SPACE = "4194304"

# systemd
DISTRO_FEATURES_append = " systemd"
VIRTUAL-RUNTIME_init_manager = "systemd"
VIRTUAL-RUNTIME_initscripts = "systemd-compat-units"

SERIAL_CONSOLES_CHECK = "${SERIAL_CONSOLES}"

IMAGE_FEATURES += " package-management"
PACKAGE_CLASSES ?= " package_rpm"

IMAGE_INSTALL_append = " dropbear"


IMAGE_INSTALL_append = " systemtap"
IMAGE_INSTALL_append = " packagegroup-core-buildessential"
IMAGE_INSTALL_append = " coreutils"

IMAGE_GEN_DEBUGFS = "1"
IMAGE_FSTYPES = "ext4 tar.bz2"
IMAGE_FSTYPES_DEBUGFS = "tar.bz2"
#USER_CLASSES += "image-combined-dbg"

# enables kernel debug symbols
KERNEL_EXTRA_FEATURES_append = " features/debug/debug-kernel.scc"

# minimal, just run-time systemtap configuration in target image
#PACKAGECONFIG_pn-systemtap = "monitor"

EOS
  cd $top_dir
}

image()
{
  cd ${work_dir}
  OEROOT=${src_dir}/poky . ${src_dir}/poky/oe-init-build-env
  cmd="bitbake $opts ${image}"
  echo $cmd
  $cmd
  cd ${top_dir}
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
  cd ${work_dir}
  OEROOT=${src_dir}/poky . ${src_dir}/poky/oe-init-build-env
  
  params="-m 4096"
  params="$params -smp 4"

  params="$params -device virtio-blk-device,drive=disk1"
  params="$params -drive id=disk1,file=$disk1,if=none,format=raw"

  bootparams=""
  bootparams="$bootparams root=/dev/vdb"

  disk

  runqemu nographic ${machine} \
    qemuparams="$params" bootparams="$bootparams" \
    $image
  cd $top_dir
}

show_images()
{
  cd ${work_dir}
  OEROOT=${src_dir}/poky . ${src_dir}/poky/oe-init-build-env
  bitbake-layers show-recipes | grep 'core-image-'
  cd $top_dir
}

show_recipes()
{
  cd ${work_dir}
  OEROOT=${src_dir}/poky . ${src_dir}/poky/oe-init-build-env
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
  arg=$1; shift

  case $arg in
    stap )
      stap_hello
      ;;
    stap-kernel )
      stap_kernel
      ;;
    * )
      cd ${work_dir}
      OEROOT=${src_dir}/poky . ${src_dir}/poky/oe-init-build-env
  
      bitbake_cmd="bitbake $opts $arg"
      echo $bitbake_cmd
      $bitbake_cmd
      ;;
  esac

  cd $top_dir
}

extract_debug()
{
  cd $top_dir
  imagedir=${work_dir}/build/tmp/deploy/images
  
  imagetar="${imagedir}/${machine}/${image}-${machine}.tar.bz2"
  tar -C $sysroot -xjf $imagetar
  
  dbgtar="${imagedir}/${machine}/${image}-${machine}-dbg.tar.bz2"
  tar -C $sysroot -xjf $dbgtar
  
  cd $top_dir
}

extract_vmlinux()
{
  cd $top_dir
  rpmdir="${work_dir}/build/tmp/deploy/rpm/${machine}"
  rpmfiles=`find $rpmdir -name "kernel-vmlinux*.rpm"`

  for rpmfile in $rpmfiles; do
    echo "extract $rpmfile"
    rpm2cpio $rpmfile | cpio -id -D $sysroot
  done

}

sysroot()
{
  . /opt/poky/2.4.4/environment-setup-aarch64-poky-linux
  export LDFLAGS=""

  cd ${work_dir}
  rm -rf ${sysroot}
  
  rpmdir=${work_dir}/build/tmp/deploy/rpm
  
  rpmfiles=`find $rpmdir -name "kernel-devsrc*.rpm"`
  for rpmfile in $rpmfiles; do
    rpm2cpio $rpmfile | cpio -id -D $sysroot
  done
  
  cd $sysroot/usr/src/kernel/
  ln -sf System.map-${release} System.map
  cd $top_dir

  cd $sysroot/usr/src/kernel/
  #. /opt/poky/2.4.4/environment-setup-aarch64-poky-linux
  #export LDFLAGS=""
  make scripts
  make prepare

  extract_debug
  extract_vmlinux
  
  cd $sysroot/usr/src/kernel/
  ln -s ../../../boot/vmlinux-4.12.28-yocto-standard vmlinux
}

stap_hello()
{
  . /opt/poky/2.4.4/environment-setup-aarch64-poky-linux
  #. /opt/poky/2.4.4/environment-setup-x86_64-pokysdk-linux

  export LDFLAGS=""

  kernel_src=$sysroot/usr/src/kernel
  tmpdir=$work_dir/tmp

  mkdir -p $tmpdir

  cd $work_dir
  command stap -v -a arm64 -B CROSS_COMPILE=$CROSS_COMPILE \
    -r $kernel_src \
    --sysroot=$sysroot \
    -e 'probe begin { log ("hello " . k) exit () } global k="world" ' \
    -m stap_hello \
    --tmpdir=$tmpdir \
    -p 4

  #echo "send stap_hello.ko to remote"
  #scp -q stap_hello.ko $remote:/home/root/
  #echo "run staprun"
  #cat - << 'EOS' | ssh -y $remote sh -s
  #{
  #  staprun stap_hello.ko
  #  rm -f stap_hello.ko
  #}
#EOS

  cd $top_dir
}

stap()
{
  . /opt/poky/2.4.4/environment-setup-aarch64-poky-linux
  export LDFLAGS=""

  kernel_src=$sysroot/usr/src/kernel
  tmpdir=$work_dir/tmp

  mkdir -p $tmpdir

  command stap \
    -v \
    -a arm64 \
    -B CROSS_COMPILE=$CROSS_COMPILE \
    --sysroot=$sysroot \
    -r $kernel_src \
    -m test_kernel \
    --tmpdir=$tmpdir \
    -p 4 \
    test_kernel.stp

  cd $top_dir
}

crosstap()
{
  cd ${work_dir}
  OEROOT=${src_dir}/poky . ${src_dir}/poky/oe-init-build-env

  cd ${work_dir}
  #ok
  command crosstap root@yocto ../test_kernel.stp -p 4 -v
  
  #ok
  #crosstap root@yocto ../test_key.stp -p 4 -v
  
  # compile error
  # crosstap root@yocto ../cycle_thief.stp -p 4 -v
  cd ${top_dir}
}

staprun()
{
  cd ${work_dir}
  scp -q test_kernel.ko $remote:/home/root/
  ssh -y $remote staprun -v test_kernel.ko
  cd ${top_dir}
}

debug()
{
  . /opt/poky/2.4.4/environment-setup-aarch64-poky-linux
  export LDFLAGS=""

  #script="${src_dir}/poky/scripts/crosstap"
  #file $script

  stap="/home/kojiro/devel/qemu_samples/yocto/work/build/tmp/work/x86_64-linux/systemtap-native/3.1-r0/recipe-sysroot-native/usr/bin/stap"

  arch="arm64"
  
  # ok
  builddir="/home/kojiro/devel/qemu_samples/yocto/work/build/tmp/work/qemuarm64-poky-linux/linux-yocto/4.12.28+gitAUTOINC+2ae65226f6_e562267bae-r0/linux-qemuarm64-standard-build"
  echo "OK"
  echo "BuildDir : $builddir"
  du -sh $builddir
  ls $builddir
  echo "" 
  
  # ng
  builddir="$work_dir/sysroot/usr/src/kernel"
  echo "" 
  echo "NOT OK"
  echo "BuildDir : $builddir"
  du -sh $builddir
  ls $builddir
  echo "" 
 

  tapset_dir="/home/kojiro/devel/qemu_samples/yocto/work/build/tmp/work/x86_64-linux/systemtap-native/3.1-r0/recipe-sysroot-native/usr/share/systemtap/tapset"

  runtime_dir="/home/kojiro/devel/qemu_samples/yocto/work/build/tmp/work/x86_64-linux/systemtap-native/3.1-r0/recipe-sysroot-native/usr/share/systemtap/runtime"

  $stap -a $arch \
    -B CROSS_COMPILE=aarch64-poky-linux- \
    -r $builddir \
    -I $tapset_dir \
    -R $runtime_dir \
    -p 4 \
    -m hoge \
    test_kernel.stp

  which stap
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

