# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI="6"

inherit flag-o-matic

DESCRIPTION="SAT solver"
HOMEPAGE="http://fmv.jku.at/picosat/"
SRC_URI="http://fmv.jku.at/${PN}/${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
IUSE="debug static-libs tools"

KEYWORDS=""

DEPEND=""
RDEPEND=""

src_prepare() {
	declare -ga PICOSAT_TOOLS=()
	use tools && PICOSAT_TOOLS+=( picosat picomus )

	if use debug; then
		append-cppflags -UNDEBUG -DLOGGING -DSTATS -DTRACE
		append-cflags -g
	else
		append-cppflags -DNDEBUG
	fi

	append-cflags -fPIC

	epatch "${FILESDIR}/${P}-makefile-lib-dep.patch"
	default
}

src_configure() {
	# the configure script is not compatible with econf
	#  work around configure.sh<>makefile<>mkconfig CFLAGS behavior
	CFLAGS="${CPPFLAGS} ${CFLAGS}"  \
		./configure $(usex {,--}debug "") || die
}

src_compile() {
	emake LIB=libpicosat.so libpicosat.so "${PICOSAT_TOOLS[@]}"
	use static-libs && emake libpicosat.a
}

src_install() {
	dolib.so libpicosat.so
	use static-libs && dolib.a libpicosat.a
	doheader picosat.h
	use tools && dobin "${PICOSAT_TOOLS[@]}"
	dodoc README NEWS
}
