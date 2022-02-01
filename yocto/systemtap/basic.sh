#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

. /opt/poky/2.4.4/environment-setup-aarch64-poky-linux

export LDFLAGS=""

KERNEL_DEVSRC_RPM=`pwd`/../kernel-devsrc-1.0-r0.qemuarm64.rpm

SYSROOT=/opt/poky/2.4.4/sysroots/aarch64-poky-linux
KERNEL_SRC=$SYSROOT/usr/src/kernel

rm -rf $KERNEL_SRC
cd $SYSROOT && rpm2cpio $KERNEL_DEVSRC_RPM | cpio -id

cd $KERNEL_SRC
make scripts
make prepare
cd $top_dir

stap \
    -v \
    -a arm64 \
    -B CROSS_COMPILE=$CROSS_COMPILE \
    -r /opt/poky/2.4.4/sysroots/aarch64-poky-linux/usr/src/kernel \
    -e 'probe begin { log ("hello " . k) exit () } global k="world" ' \
    -m stap_hello

