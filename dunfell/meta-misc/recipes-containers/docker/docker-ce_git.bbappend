#
# $ bitbake linux-yocto -c kernel_configcheck -f
#
# $ bitbake linux-yocto -c savedefconfig
#
# $ bitbake virtual/kernel -e | grep -e 'LINUX_VERSION='
#
# $ bitbake virtual/kernel -c cleansstate
#

do_install_append() {
  install -d ${D}${sysconfdir}/init.d
  install -m 0755 ${WORKDIR}/docker.init ${D}${sysconfdir}/init.d/docker.init
}

