# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

inherit user

DESCRIPTION="The ultimate open source web chat platform"
HOMEPAGE="https://rocket.chat/"
SRC_URI="https://rocket.chat/releases/${PV}/download -> ${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

RDEPEND="dev-db/mongodb
		 >=net-libs/nodejs-6.9.1
		 media-gfx/graphicsmagick[jpeg,png]"
DEPEND="${RDEPEND}"

ROCKET_DEST="/usr/share/${PN}"
ROCKET_LOG="/var/log/${PN}"
ROCKET_USER="rocket"
ROCKET_GROUP="rocket"

pkg_setup() {
	enewgroup ${ROCKET_GROUP}
	enewuser ${ROCKET_USER} -1 -1 "${ROCKET_DEST}" ${ROCKET_GROUP}
}

src_unpack() {
	default
	mv "${WORKDIR}/bundle" "${WORKDIR}/${P}"
}

src_prepare() {
	default
	pushd "programs/server"
	npm install || die "Error in npm install"
	popd
}

src_install() {
	mkdir -p "${D}${ROCKET_DEST}"
	cp -a . "${D}${ROCKET_DEST}"

	keepdir "${ROCKET_LOG}"
	fowners "${ROCKET_USER}":"${ROCKET_GROUP}" "${ROCKET_LOG}"

	# This is to enable webhook integration with script support
	keepdir "${ROCKET_DEST}/.babel-cache"
	fowners "${ROCKET_USER}":"${ROCKET_GROUP}" "${ROCKET_DEST}/.babel-cache"

	newconfd "${FILESDIR}"/${PN}.confd ${PN}
	newinitd "${FILESDIR}"/${PN}.initd ${PN}
}
