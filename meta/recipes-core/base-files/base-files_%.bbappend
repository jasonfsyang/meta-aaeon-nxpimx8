FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
            file://issue \
	        file://issue.net \
"

PACKAGE_ARCH = "${MACHINE_ARCH}"

do_install:append () {
    install -d ${D}/etc
	install -m 0755 ${WORKDIR}/issue ${D}/etc/issue
	install -m 0755 ${WORKDIR}/issue.net ${D}/etc/issue.net
}

FILES:${PN} += " /etc/issue"
FILES:${PN} += " /etc/issue.net"
