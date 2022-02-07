SRCREV = "044a0640985ef007c0b2fb6eaf660d9d51800cda"
PV = "4.2"

FILESEXTRAPATHS_prepend := "${THISDIR}/systemtap:"

SRC_URI = "git://sourceware.org/git/systemtap.git;branch=master \
           file://0001-Do-not-let-configure-write-a-python-location-into-th.patch \
           file://0001-Install-python-modules-to-correct-library-dir.patch \
           file://0001-staprun-stapbpf-don-t-support-installing-a-non-root.patch \
"


