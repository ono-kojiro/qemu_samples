DESCRIPTION = "myapp"
HOMEPAGE = "https://github.com/ono-kojiro/myapp"

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRCREV = "f52db1b43c0a6c94a64e96dffa80c86a5196fe9d"
SRC_URI = "git://github.com/ono-kojiro/myapp.git;branch=main;protocol=https"

S = "${WORKDIR}/git"

SRC_URI[sha256sum] = "dbd4f3a1223dfa9ce8a6e8b6d336b63ddb2bea4cc8b7d238478619d170768fed"

inherit autotools

do_configure_prepend() {
  cd ${S}
  autoreconf -vi
  cd ${WORKDIR}/build
}
