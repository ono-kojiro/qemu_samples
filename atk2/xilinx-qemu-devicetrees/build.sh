#!/bin/sh

set -e

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

realname="qemu-devicetrees"
pkgname="${realname}-xilinx"
version="2022.1"

src_urls=""
#src_urls="$src_urls https://github.com/Xilinx/qemu-devicetrees.git"
src_urls="$src_urls https://github.com/Xilinx/qemu-devicetrees/archive/refs/tags/xilinx_v${version}.tar.gz"

url="https://github.com/Xilinx/qemu-devicetrees"

sourcedir=$top_dir/work/sources
builddir=$top_dir/work/build
destdir=$top_dir/work/dest/${pkgname}-${version}

outputdir=$top_dir

help()
{
  cat - << 'EOS'
  fetch
  extract
  configure
  compile
  install
  custom_install
  package
EOS

}

prepare()
{
  sudo apt -y install python-is-python3
  sudo apt -y install device-tree-compiler
}

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
        if [ ! -d "${builddir}/${pkgname}_v${version}" ]; then
          tar -C ${builddir} -xvf ${sourcedir}/${archive}
        else
          echo "skip extract"
        fi
        ;;
      *.zip )
        if [ ! -d "${builddir}/${pkgname}_v${version}" ]; then
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
  cd ${builddir}/${pkgname}_v${version}
  cd ${top_dir}
}

config()
{
  configure
}

compile()
{
  cd ${builddir}/${pkgname}_v${version}
  make V=1
  cd ${top_dir}
}

install()
{
  cd ${builddir}/${pkgname}_v${version}
  mkdir -p ${destdir}/usr/share/qemu/xilinx/
  cp -a LATEST/* ${destdir}/usr/share/qemu/xilinx/
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

