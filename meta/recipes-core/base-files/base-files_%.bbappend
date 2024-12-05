FILESEXTRAPATHS:prepend := "${THISDIR}/base-files:"

SRC_URI += "file://issue.net file://issue"

do_install:append () {
    install -d ${D}${sysconfdir}/etc
	install -m 0755 ${WORKDIR}/issue ${D}${sysconfdir}/etc/issue
	install -m 0755 ${WORKDIR}/issue.net ${D}${sysconfdir}/etc/issue.net
}

FILES:${PN} += "${sysconfdir}/etc"
