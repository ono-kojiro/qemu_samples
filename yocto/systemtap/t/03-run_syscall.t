#!/bin/sh

set -e

echo "1..1"

remote="192.168.7.2"

cat - << 'EOS' | ssh -y $remote sh -s
{
  rm -f stap_hello.ko
  name="stap_syscall"

  timeout --preserve-status 5 staprun ${name}.ko
  if [ $? -eq 0 ]; then
    echo "ok : staprun syscall"
  else
    echo "not ok : staprun syscall"
  fi
}
EOS

