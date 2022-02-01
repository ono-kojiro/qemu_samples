#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

sdk_root=/opt/poky/2.4.4

echo "remove $sdk_root ..."
rm -rf $sdk_root

echo "install sdk ..."
bash ~/Downloads/poky-glibc-x86_64-core-image-sato-aarch64-toolchain-2.4.4.sh

. /opt/poky/2.4.4/environment-setup-aarch64-poky-linux

export LDFLAGS=""

KERNEL_DEVSRC_RPM=`pwd`/../kernel-devsrc-1.0-r0.qemuarm64.rpm

SYSROOT=/opt/poky/2.4.4/sysroots/aarch64-poky-linux
KERNEL_SRC=$SYSROOT/usr/src/kernel

echo "install $KERNEL_DEVSRC_RPM ..."
rm -rf $KERNEL_SRC
cd $SYSROOT && rpm2cpio $KERNEL_DEVSRC_RPM | cpio -id

echo "make scripts and make prepare ..."
cd $KERNEL_SRC
make scripts
make prepare
cd $top_dir

echo "build stap_hello"

stap \
    -v \
    -a arm64 \
    -B CROSS_COMPILE=$CROSS_COMPILE \
    -r /opt/poky/2.4.4/sysroots/aarch64-poky-linux/usr/src/kernel \
    -e 'probe begin { log ("hello " . k) exit () } global k="world" ' \
    -m stap_hello

