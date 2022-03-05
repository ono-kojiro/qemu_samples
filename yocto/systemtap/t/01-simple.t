#!/bin/sh

set -e

echo "1..2"

remote="192.168.7.2"

cat - << 'EOS' | ssh -y $remote sh -s
{
  rm -f stap_hello.ko

  stap \
    -e 'probe begin { log ("hello " . k) exit () } global k="world" ' \
    -m stap_hello

  if [ $? -eq 0 ]; then
    echo "ok : native"
  else
    echo "not ok : native stap"
  fi

  staprun stap_hello.ko
  if [ $? -eq 0 ]; then
    echo "ok : native"
  else
    echo "not ok : native stap"
  fi
}
EOS

