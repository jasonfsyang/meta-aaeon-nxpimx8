FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://001-imx-atf.patch"

PACKAGE_ARCH = "${MACHINE_ARCH}"
