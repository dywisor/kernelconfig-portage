# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI="6"

inherit eutils

DESCRIPTION="aspect-oriented extension of C and C++ languages"
HOMEPAGE="http://www.aspectc.org/"
SRC_URI="http://www.aspectc.org/releases/${PV}/ac-${PV}.tar.gz"

LICENSE="GPL-2+ Boost-1.0"
SLOT="0"
IUSE="+libpuma"

KEYWORDS=""

_CDEPEND="
	dev-libs/libxml2 sys-libs/ncurses:= sys-libs/zlib"
DEPEND="${_CDEPEND}
	|| ( sys-devel/clang:0/3.7 sys-devel/clang:0/3.6 sys-devel/clang:0/3.4 )
"
RDEPEND="${_CDEPEND}"

S="${WORKDIR}/aspectc++"

src_prepare() {
	# "cp --reflink" from multibuild.eclass
	local -a cp_args=()
	if cp --reflink=auto --version &>/dev/null; then
		# enable reflinking if possible to make this faster
		cp_args+=( --reflink=auto )
	fi

	epatch "${FILESDIR}/aspectcpp-puma-fix-sed.patch"
	default
	cp -p -R "${cp_args[@]}" "${S}/Puma" "${S}/MiniPuma" || die
}

src_compile() {
	local ac_target="linux-release"
	local -a margs=()
	local -a margs_minipuma=()

	margs+=( TARGET="${ac_target}" )
	margs_minipuma+=( PUMA="${S}/MiniPuma" PUMA_LIB=MiniPuma )

	# needs bootstrapping:
	#   a (minimal) libPuma is required for building ac++,
	#   and a full libPuma needs ac++
	einfo "Building libMiniPuma"
	# ROOT needs to be set to Puma's source directory, build fails otherwise
	emake -C MiniPuma "${margs[@]}" \
		ROOT="${S}/MiniPuma" MINI=1

	einfo "Building ac++"
	emake -C AspectC++ "${margs[@]}" "${margs_minipuma[@]}" \
		SHARED=1 FRONTEND=Clang

	einfo "Building ag++"
	emake -C Ag++ "${margs[@]}" "${margs_minipuma[@]}" \
		SHARED=1

	if use libpuma; then
		einfo "Building libPuma"
		emake -C Puma "${margs[@]}" \
			ROOT="${S}/Puma" MINI="" \
			AC="${S}/AspectC++/bin/${ac_target}/ac++" \
			EXTENSIONS="acppext gnuext winext"
	fi

	#if use frontend-puma then compile AspectC++ again
}

src_install() {
	local ac_target="linux-release"

	dobin "AspectC++/bin/${ac_target}/ac++"
	dobin "Ag++/bin/${ac_target}/ag++"

	if use libpuma; then
		dolib.a "Puma/lib/${ac_target}/libPuma.a"
		doheader -r "Puma/include/Puma"
		doheader -r "Puma/extern/lexertl"
	fi
}
