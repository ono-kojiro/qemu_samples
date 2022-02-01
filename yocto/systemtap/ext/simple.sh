#!/bin/sh

set -e

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

. ~/poky_sdk/environment-setup-aarch64-poky-linux
export LDFLAGS=""

SYSROOT=~/poky_sdk/tmp/sysroots/qemuarm64
KERNEL_SRC=$SYSROOT/usr/src/kernel

stap \
    -v \
    -a arm64 \
    -B CROSS_COMPILE=$CROSS_COMPILE \
    -r $KERNEL_SRC \
    -e 'probe begin { log ("hello " . k) exit () } global k="world" ' \
    -m stap_hello

scp stap_hello.ko 192.168.7.2:/home/root/
ssh -y 192.168.7.2 staprun stap_hello.ko

