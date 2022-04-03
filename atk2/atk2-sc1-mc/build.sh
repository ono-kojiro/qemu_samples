#!/bin/sh

set -e

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

realname="atk2-sc1-mc"
pkgname="${realname}"
version="1.4.2"

src_urls=""
#src_urls="$src_urls https://github.com/Xilinx/qemu-devicetrees.git"
#src_urls="$src_urls https://www.toppers.jp/download.cgi/atk2-sc1-mc_zynqmp_r5_gcc-20190620.tar.gz"
src_urls="$src_urls https://www.toppers.jp/download.cgi/atk2-sc1-mc_zynqmp_r5_gcc-20170929.tar.gz"

url="https://www.toppers.jp/index.html"

sourcedir=$top_dir/work/sources
builddir=$top_dir/work/build
destdir=$top_dir/work/dest/${pkgname}-${version}

outputdir=$top_dir


all()
{
  fetch
  extract
  configure
  compile
  install
  custom_install
  package
}

fetch()
{
  mkdir -p $sourcedir

  for src_url in $src_urls; do
    archive=`basename $src_url`
    case $src_url in
      *.gz | *.zip )
        if [ ! -e "$sourcedir/$archive" ]; then
            wget $src_url
            mv -f $archive $sourcedir/
        else
            echo "skip wget"
        fi
        ;;
      *.git )
        dirname=${archive%.git}
        if [ ! -d "${sourcedir}/${dirname}" ]; then
            mkdir -p ${sourcedir}
            git -C ${sourcedir} clone $src_url
        else
            echo "skip git-clone"
        fi
        ;;
      * )
        echo "ERROR : unknown extension, $src_url"
        exit 1
        ;;
    esac
  done

}

extract()
{
  mkdir -p ${builddir}
  
  for src_url in $src_urls; do
    archive=`basename $src_url`
    case $src_url in
      *.gz )
        if [ ! -d "${builddir}/${pkgname}_${version}" ]; then
          tar -C ${builddir} -xvf ${sourcedir}/${archive}
        else
          echo "skip extract"
        fi
        ;;
      *.zip )
        if [ ! -d "${builddir}/${pkgname}_${version}" ]; then
          unzip ${sourcedir}/${archive} -d ${builddir}
        else
          echo "skip extract"
        fi
        ;;
      *.git )
        dirname=${archive%.git}
        if [ ! -d "${builddir}/${dirname}" ]; then
            mkdir -p ${builddir}
            cp -a ${sourcedir}/${dirname} ${builddir}/
        else
            echo "skip extract"
        fi
        ;;
      * )
        echo "ERROR : unknown extension, $src_url"
        exit 1
        ;;
    esac
  done

}

configure()
{
  cd ${builddir}/${pkgname}_${version}
  mkdir -p obj
  cd obj
  ../configure -T zynqmp_r5_gcc -g /usr/bin/cfg
  #../configure -T zynqmp_r5_gcc
  cd ${top_dir}
}

config()
{
  configure
}

compile()
{
  cd ${builddir}/${pkgname}_${version}
  mkdir -p obj
  cd obj
  make GCC_TARGET=arm-none-eabi
  cd ${top_dir}
}

run()
{
  qemu-system-aarch64 \
    -M arm-generic-fdt \
    -nographic \
    -serial mon:stdio \
    -dtb /usr/share/qemu/xilinx/SINGLE_ARCH/zcu102-arm.dtb \
    -device loader,file=${builddir}/${pkgname}_${version}/obj/${pkgname},cpu-num=4 \
    -device loader,addr=0xff5e023c,data=0x80008fde,data-len=4 \
    -device loader,addr=0xff9a0000,data=0x80000218,data-len=4
}

install()
{
  cd ${builddir}/${pkgname}_${version}

  rm -rf ${destdir}

  mkdir -p ${destdir}/usr/share/${pkgname}
  cp -a ./obj/${pkgname} ${destdir}/usr/share/${pkgname}/
  
  mkdir -p ${destdir}/usr/bin
  cat - << EOS > ${destdir}/usr/bin/${pkgname}
#!/usr/bin/env sh

qemu-system-aarch64 \
  -M arm-generic-fdt \
  -nographic \
  -serial mon:stdio \
  -dtb /usr/share/qemu/xilinx/SINGLE_ARCH/zcu102-arm.dtb \
  -device loader,file=/usr/share/${pkgname}/${pkgname},cpu-num=4 \
  -device loader,addr=0xff5e023c,data=0x80008fde,data-len=4 \
  -device loader,addr=0xff9a0000,data=0x80000218,data-len=4

EOS

  chmod 755 ${destdir}/usr/bin/${pkgname}

  cd ${top_dir}
}

custom_install()
{
  :
}

package()
{
	mkdir -p $destdir/DEBIAN

    username=`git config user.name`
    email=`git config user.email`

cat << EOS > $destdir/DEBIAN/control
Package: $pkgname
Maintainer: $username <$email>
Architecture: amd64
Version: $version
Description: $pkgname
EOS
	fakeroot dpkg-deb --build $destdir $outputdir
}

clean()
{
  rm -rf $builddir
  rm -rf $destdir
}

if [ "$#" = 0 ]; then
  all
fi

for target in "$@"; do
	num=`LANG=C type $target | grep 'function' | wc -l`
	if [ $num -ne 0 ]; then
		$target
	else
		echo invalid target, "$target"
	fi
done

