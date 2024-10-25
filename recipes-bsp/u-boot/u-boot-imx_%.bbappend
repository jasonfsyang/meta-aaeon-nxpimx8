FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://004-uboot-all.patch"

PACKAGE_ARCH = "${MACHINE_ARCH}"
