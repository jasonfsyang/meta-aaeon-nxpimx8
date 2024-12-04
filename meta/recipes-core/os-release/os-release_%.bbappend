FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
            file://os-release \
"

PACKAGE_ARCH = "${MACHINE_ARCH}"

do_install:append () {
    install -d ${D}/etc
	install -m 0755 ${WORKDIR}/os-release ${D}/etc/os-release
}

FILES:${PN} += " /etc/os-release"
