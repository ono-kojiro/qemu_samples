path_add() {
  if [ -d "$1" ]; then
    echo ":$PATH:" | grep ":$1:" > /dev/null 2>&1
	if [ $? -ne 0 ]; then
      PATH="$1:$PATH"
	fi
  fi
}

add_ld_library_path() {
  if [ -d "$1" ]; then
    echo ":$LD_LIBRARY_PATH:" | grep ":$1:" > /dev/null 2>&1
	if [ $? -ne 0 ]; then
      LD_LIBRARY_PATH="$1:$LD_LIBRARY_PATH"
	fi
  fi
}

ROOT=/opt/powerpc-eabi-4.3.3

path_add $ROOT/bin
export PATH

add_ld_library_path $ROOT/lib
export LD_LIBRARY_PATH

