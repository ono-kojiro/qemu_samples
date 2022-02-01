#!/bin/sh

set -e

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

. /opt/poky/2.4.4/environment-setup-aarch64-poky-linux
export LDFLAGS=""

SYSROOT=/opt/poky/2.4.4/sysroots/aarch64-poky-linux
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

