FILESEXTRAPATHS:prepend := "${THISDIR}/os-release:"
LICENSE = "CLOSED"

SRC_URI += "file://os-release"

do_install () {
    install -d ${D}/etc
    install -m 0755 ${WORKDIR}/os-release ${D}/etc/os-release
}

FILES:${PN} += "/etc/os-release"
