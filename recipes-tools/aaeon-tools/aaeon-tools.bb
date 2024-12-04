SUMMARY = "tools required for service"
LICENSE = "CLOSED"

SRC_URI = "\
	file://srgimx8cfg \
	file://mdio-tool \
	file://imx8_plus_emmc_flasher.sh \
	file://erase_emmc.sh \
	file://sysbench \
	file://boot.scr \
	file://rtw_options.conf \
	file://quectel-cm.tar;unpack=0 \
	file://rtl8822b_config.bin \
	file://rtl8822b_fw.bin \
	file://imx8mp_loop_test_RS232.sh \
	file://imx8mp_loop_test_RS422.sh \
	file://imx8mp_loop_test_RS485.sh \
	file://test.tar;unpack=0 \
"
SRC_URI += "${EXTRA_UBOOT_BOOTLOADER_FILE}"

S = "${WORKDIR}"


do_install () {
	install -d ${D}/home/srt/eeprom
	install -m 0755 ${WORKDIR}/srgimx8cfg ${D}/home/srt/eeprom/srgimx8cfg

	install -d ${D}/usr/sbin
	install -m 0755 ${WORKDIR}/mdio-tool ${D}/usr/sbin/mdio-tool
	install -m 0755 ${WORKDIR}/imx8_plus_emmc_flasher.sh ${D}/usr/sbin/imx8_plus_emmc_flasher.sh
	install -m 0755 ${WORKDIR}/erase_emmc.sh ${D}/usr/sbin/erase_emmc.sh
	install -m 0755 ${WORKDIR}/sysbench ${D}/usr/sbin/sysbench
	install -m 0755 ${WORKDIR}/boot.scr ${D}/usr/sbin/boot.scr	
	install -m 0755 ${WORKDIR}/quectel-cm.tar ${D}/usr/sbin/quectel-cm.tar
	
	install -d ${D}/etc/modprobe.d
	install -m 0755 ${WORKDIR}/rtw_options.conf ${D}/etc/modprobe.d/rtw_options.conf
	
	install -d ${D}/lib/firmware/rtl_bt
	install -m 0755 ${WORKDIR}/rtl8822b_config.bin ${D}/lib/firmware/rtl_bt/rtl8822b_config.bin
	install -m 0755 ${WORKDIR}/rtl8822b_fw.bin ${D}/lib/firmware/rtl_bt/rtl8822b_fw.bin
	
	install -d ${D}/LoopTest
	install -m 0755 ${WORKDIR}/imx8mp_loop_test_RS232.sh ${D}/LoopTest/imx8mp_loop_test_RS232.sh
	install -m 0755 ${WORKDIR}/imx8mp_loop_test_RS422.sh ${D}/LoopTest/imx8mp_loop_test_RS422.sh
	install -m 0755 ${WORKDIR}/imx8mp_loop_test_RS485.sh ${D}/LoopTest/imx8mp_loop_test_RS485.sh
	
	install -m 0755 ${WORKDIR}/test.tar ${D}/test.tar
	
	install -d ${D}/opt/images/yocto
	install -m 0755 ${WORKDIR}/${EXTRA_UBOOT_BOOTLOADER} ${D}/opt/images/yocto/imx-boot-srg-imx8p-flash_evk
}
 
do_package_qa[noexec] = "1"


FILES:${PN} += " /home/srt/eeprom/srgimx8cfg"

FILES:${PN} += " /usr/sbin/mdio-tool"
FILES:${PN} += " /usr/sbin/imx8_plus_emmc_flasher.sh"
FILES:${PN} += " /usr/sbin/erase_emmc.sh"
FILES:${PN} += " /usr/sbin/sysbench"
FILES:${PN} += " /usr/sbin/boot.scr"
FILES:${PN} += " /usr/sbin/quectel-cm.tar"

FILES:${PN} += " /etc/modprobe.d/rtw_options.conf"

FILES:${PN} += " /lib/firmware/rtl_bt/rtl8822b_config.bin"
FILES:${PN} += " /lib/firmware/rtl_bt/rtl8822b_fw.bin"

FILES:${PN} += " /LoopTest/imx8mp_loop_test_RS232.sh"
FILES:${PN} += " /LoopTest/imx8mp_loop_test_RS422.sh"
FILES:${PN} += " /LoopTest/imx8mp_loop_test_RS485.sh"

FILES:${PN} += " /test.tar"

FILES:${PN} += " /opt/images/yocto/imx-boot-srg-imx8p-flash_evk"
