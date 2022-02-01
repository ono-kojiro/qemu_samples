#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

sdk_root=~/poky_sdk

echo "remove $sdk_root ..."
rm -rf $sdk_root

echo "install ext sdk ..."
bash ~/Downloads/poky-glibc-x86_64-core-image-minimal-aarch64-toolchain-ext-2.4.4.sh -y

. ~/poky_sdk/environment-setup-aarch64-poky-linux
export LDFLAGS=""

KERNEL_DEVSRC_RPM=`pwd`/../../kernel-devsrc-1.0-r0.qemuarm64.rpm

SYSROOT=~/poky_sdk/tmp/sysroots/qemuarm64
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
    -r $KERNEL_SRC \
    -e 'probe begin { log ("hello " . k) exit () } global k="world" ' \
    -m stap_hello

scp stap_hello.ko 192.168.7.2:/home/root/
ssh -y 192.168.7.2 staprun stap_hello.ko

