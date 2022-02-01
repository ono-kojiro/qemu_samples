#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

#. /opt/poky/2.4.4/environment-setup-aarch64-poky-linux
. ~/poky_sdk/environment-setup-aarch64-poky-linux

export LDFLAGS=""

KERNEL_DEVSRC_RPM=`pwd`/../../kernel-devsrc-1.0-r0.qemuarm64.rpm

SYSROOT=~/poky_sdk/tmp/sysroots/qemuarm64

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
    -r $KERNEL_SRC \
    -e 'probe begin { log ("hello " . k) exit () } global k="world" ' \
    -m stap_hello

scp stap_hello.ko 192.168.7.2:/home/root/
ssh -y 192.168.7.2 staprun stap_hello.ko

