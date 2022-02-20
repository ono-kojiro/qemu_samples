#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir


url=https://github.com/freedomtan/aarch64-bare-metal-qemu.git

work_dir=`basename -s .git $url`
  
CROSS_COMPILE=aarch64-none-elf-

. ./aarch64-none-elf-gcc.bashrc

usage()
{
  echo "usage : $0 [OPTIONS] target1 target2 ..."
}

fetch()
{
  dirname=`basename -s .git $url`

  if [ ! -d $dirname ]; then
    git clone $url
  else
    git -C $dirname pull
  fi

  cd $top_dir
}

build()
{
  cd $work_dir
  make
  cd $top_dir
}

run()
{
  echo "press Ctrl+A, x to finish qemu."
  cd $work_dir
  qemu-system-aarch64 -M virt -cpu cortex-a57 -nographic -kernel test64.elf
  cd $top_dir
}

main()
{
  while [ $# -ne 0 ]; do
    case $1 in
      -h | --help)
        usage
        exit 1
        ;;
      -v | --version)
        usage
        exit 1
        ;;
      *)
        break
        ;;
    esac

    shift
  done

  if [ $# -eq 0 ]; then
    usage
    exit 1
  fi

  for arg in "$@"; do
    LANG=C type $arg | grep 'function' > /dev/null 2>&1
    if [ $? -eq 0 ]; then
      $arg
    else
      default_target $arg
    fi
  done
}

main "$@"

