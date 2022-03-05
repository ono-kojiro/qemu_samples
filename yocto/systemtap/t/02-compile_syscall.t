#!/bin/sh

set -e

echo "1..1"

remote="192.168.7.2"

cat - << 'EOS' | ssh -y $remote sh -s
{
  rm -f stap_hello.ko

  name="stap_syscall"

  stap \
    -e 'global ops; probe syscall.* { ops[execname()] <<< 1; }' \
    -p 4 \
    -m $name

  if [ $? -eq 0 ]; then
    echo "ok : compile sycall"
  else
    echo "not ok : compile syscall"
  fi
}
EOS

