#
# $ bitbake linux-yocto -c kernel_configcheck -f
#
# $ bitbake linux-yocto -c savedefconfig
#
# $ bitbake virtual/kernel -e | grep -e 'LINUX_VERSION='
#
# $ bitbake virtual/kernel -c cleansstate
#

SRC_URI_remove = "http://linuxcontainers.org/downloads/${BPN}-${PV}.tar.gz"
SRC_URI_append = "http://linuxcontainers.org/downloads/${BPN}/${BPN}-${PV}.tar.gz"

