# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6

inherit bash-completion-r1 eutils flag-o-matic systemd user

DESCRIPTION="High-performance authoritative-only DNS server"
HOMEPAGE="https://www.knot-dns.cz"
SRC_URI="https://secure.nic.cz/files/knot-dns/${P}.tar.xz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="caps +daemon dnstap doc +fastparser idn static-libs systemd +utils"

RDEPEND=">=net-libs/gnutls-3.3:=
	>=dev-libs/jansson-2.3
	>=dev-db/lmdb-0.9.15
	>=dev-libs/userspace-rcu-0.5.4
	dev-libs/libedit
	caps? ( >=sys-libs/libcap-ng-0.6.4 )
	dnstap? (
		dev-libs/fstrm
		dev-libs/protobuf-c
	)
	idn? ( net-dns/libidn )
	systemd? ( sys-apps/systemd )"
DEPEND="${RDEPEND}
	virtual/pkgconfig
	doc? ( dev-python/sphinx )"
REQUIRED_USE="
	caps? ( daemon )
	dnstap? ( daemon )
	idn? ( daemon )
	systemd? ( daemon )"

pkg_setup() {
	if use daemon; then
		enewgroup knot 53
		enewuser knot 53 -1 /var/lib/knot knot
	fi
}

src_configure() {
	local my_econf=

	if use daemon; then
		my_econf="${my_econf} --with-storage=${EPREFIX}/var/lib/${PN}"
		my_econf="${my_econf} --with-rundir=${EPREFIX}/var/run/${PN}"
	fi
	if use utils; then
		my_econf="${my_econf} --with-bash-completions=$(get_bashcompdir)"
	fi
	econf \
		--with-lmdb \
		${my_econf} \
		$(use_enable daemon) \
		$(use_enable fastparser) \
		$(use_enable dnstap) \
		$(use_enable doc documentation) \
		$(use_with idn libidn) \
		$(use_enable static-libs static) \
		$(use_enable utils utilities) \
		--enable-systemd=$(usex systemd) \
		|| die "econf failed"
}

src_compile() {
	append-cflags -fPIC
	default

	if use doc; then
		emake -C doc html
		HTML_DOCS=( doc/_build/html/{*.html,*.js,_sources,_static} )
	fi
}

src_test() {
	emake check
}

src_install() {
	default

	if use daemon; then
		keepdir /var/lib/${PN}

		newinitd "${FILESDIR}"/knot.initd knot
		systemd_dounit "${FILESDIR}"/knot.service
		systemd_newtmpfilesd "${FILESDIR}"/knot.tmpfilesd knot.conf
	fi
}
