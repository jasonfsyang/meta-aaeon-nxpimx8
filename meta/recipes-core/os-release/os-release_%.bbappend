FILESEXTRAPATHS:prepend := "${THISDIR}/os-release:"

SRC_URI += "file://os-release"


do_install:append () {
    install -d ${D}${sysconfdir}/etc
	install -m 0755 ${WORKDIR}/os-release ${D}${sysconfdir}/etc/os-release
}

FILES:${PN} += "${sysconfdir}/etc"
