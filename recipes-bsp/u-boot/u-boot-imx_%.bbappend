FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://003-uboot-all.patch"

PACKAGE_ARCH = "${MACHINE_ARCH}"
