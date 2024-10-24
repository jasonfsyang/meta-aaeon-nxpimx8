SUMMARY = "tools required for service"
LICENSE = "CLOSED"

SRC_URI = "\
	file://ethernet.service \
	file://gpio.service \
	file://watchdog.service \
	file://lancfg.sh \
	file://setup_gpios.sh \
	file://watchdog.sh \
"

S = "${WORKDIR}"


do_install () {
	install -d ${D}/lib/systemd/system
	install -m 0755 ${WORKDIR}/ethernet.service ${D}/lib/systemd/system
	install -m 0755 ${WORKDIR}/gpio.service ${D}/lib/systemd/system
	install -m 0755 ${WORKDIR}/watchdog.service ${D}/lib/systemd/system
	
	install -d ${D}/usr/sbin
	install -m 0755 ${WORKDIR}/lancfg.sh ${D}/usr/sbin
	install -m 0755 ${WORKDIR}/setup_gpios.sh ${D}/usr/sbin
	install -m 0755 ${WORKDIR}/watchdog.sh ${D}/usr/sbin
	
	install -d ${D}/lib/systemd/system/multi-user.target.wants
	ln -sf ${D}/lib/systemd/system/ethernet.service ${D}/lib/systemd/system/multi-user.target.wants/ethernet.service
	ln -sf ${D}/lib/systemd/system/gpio.service ${D}/lib/systemd/system/multi-user.target.wants/gpio.service
	ln -sf ${D}/lib/systemd/system/watchdog.service ${D}/lib/systemd/system/multi-user.target.wants/watchdog.service
}
 
do_package_qa[noexec] = "1"


FILES:${PN} += " /lib/systemd/system/ethernet.service"
FILES:${PN} += " /lib/systemd/system/gpio.service"
FILES:${PN} += " /lib/systemd/system/watchdog.service"

FILES:${PN} += " /lib/systemd/system/multi-user.target.wants/ethernet.service"
FILES:${PN} += " /lib/systemd/system/multi-user.target.wants/gpio.service"
FILES:${PN} += " /lib/systemd/system/multi-user.target.wants/watchdog.service"

FILES_${PN} += " /lib/systemd/system/ethernet.service"
FILES_${PN} += " /lib/systemd/system/gpio.service"
FILES_${PN} += " /usr/sbin/lancfg.sh"
FILES_${PN} += " /usr/sbin/setup_gpios.sh"
FILES_${PN} += " /lib/systemd/system/watchdog.service"
FILES_${PN} += " /usr/sbin/watchdog.sh"


