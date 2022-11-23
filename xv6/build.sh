#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

build_dir=_build

help()
{
  echo "usage : $0 <target>"
  echo "  targets :"
  echo "    fetch, config, build, run, clean mclean"
}

prepare()
{
  sudo apt install libgcc-11-dev-i386-cross
  sudo apt install qemu-system-x86
}

all()
{
  fetch
  config
  build
}

fetch()
{
  if [ ! -e xv6-net ]; then
    git clone https://github.com/pandax381/xv6-net.git
  else
    git -C xv6-net pull
  fi

  if [ ! -e xv6-public ]; then
    git clone https://github.com/mit-pdos/xv6-public.git
  else
    git -C xv6-public pull
  fi
}

config()
{
  mkdir -p $build_dir
  cd $build_dir
  cmake -G "Unix Makefiles" ..
  cd $top_dir
}

build()
{
  cd $build_dir
  make VERBOSE=1
  cd $top_dir
}

run()
{
  cd $build_dir
  make qemu
  cd $top_dir
}

clean()
{
  cd $build_dir
  make clean
  cd $top_dir
}


mclean()
{
  rm -rf $build_dir
  #rm -rf xv6-net
  #rm -rf xv6-public
}

if [ $# -eq 0 ]; then
  all
fi

for target in "$@" ; do
  LANG=C type $target | grep function > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    $target
  else
    echo "$target is not a shell function"
	exit $res
  fi
done

