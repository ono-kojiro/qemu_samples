#!/bin/sh

set -e

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

realname="asp3"
pkgname=asp3
version=3.6

src_urls=""
src_urls="$src_urls https://www.toppers.jp/download.cgi/asp3_zybo_z7_gcc-20210105.zip"

url=https://www.toppers.jp/index.html

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
        if [ ! -d "${builddir}/${pkgname}-${version}" ]; then
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

  rm -rf ./obj
  mkdir -p obj

  cd obj
  ../configure.rb -T zybo_z7_gcc
  cd ${top_dir}
}

config()
{
  configure
}

compile()
{
  cd ${builddir}/${pkgname}_${version}
  cd obj
  make OBJNAME=asp3
  cd ${top_dir}
}

run()
{
  cd ${builddir}/${pkgname}_${version}
  cd obj
  #make runq
  qemu-system-arm -M xilinx-zynq-a9 -semihosting -m 512M \
        -serial null -serial mon:stdio -nographic -smp 1 -kernel asp3

  cd ${top_dir}
}

install()
{
  cd ${builddir}/${pkgname}_${version}
  rm -rf ${destdir}

  mkdir -p ${destdir}/usr/share/asp3
  cp -f ./obj/asp3 ${destdir}/usr/share/asp3/

  mkdir -p ${destdir}/usr/bin
  cat - << EOS > ${destdir}/usr/bin/asp3
#!/usr/bin/env sh
qemu-system-arm -M xilinx-zynq-a9 -semihosting -m 512M \
  -serial null -serial mon:stdio -nographic -smp 1 -kernel /usr/share/asp3/asp3
EOS

  chmod 755 ${destdir}/usr/bin/asp3

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

