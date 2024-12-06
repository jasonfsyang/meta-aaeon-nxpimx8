FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append:mydistro = " \
	    file://issue.net \
		file://issue \
           "