# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI="6"

EGIT_REPO_URI="https://i4gerrit.informatik.uni-erlangen.de/undertaker"

inherit git-r3

DESCRIPTION="compile KConfig files to boolean formulae"
HOMEPAGE="http://vamos.informatik.uni-erlangen.de/trac/undertaker"
SRC_URI=""

# undertaker is GPL-3+, scripts/ is GPL-2, bundled picosat is MIT
LICENSE="GPL-3+ GPL-2 !system-picosat? ( MIT )"
SLOT="0"
IUSE="system-picosat"

KEYWORDS=""

# Note: system-picosat version range is strict for now,
#       picosat-965 did not work straightaway
# Also, picosat debug builds don't work with formulae produced by satyr
_CDEPEND="
	>=dev-libs/boost-1.53[threads]
	system-picosat? ( =dev-libs/picosat-936[-debug] )"
DEPEND="${_CDEPEND}
	dev-cpp/AspectC++[libpuma]
	dev-cpp/pstreams"
RDEPEND="${_CDEPEND}"

src_prepare() {
	local version
	# dev-cpp/pstreams installs its header as pstream.h,
	# undertaker assumes pstreams/pstream.h
	local -a PATCHES=(
		"${FILESDIR}/undertaker-fix-pstream-include.patch"
		"${FILESDIR}/undertaker-unbundle-picosat.patch"
	)

	# generate-version.sh produces some git errors, but succeeds.
	# In particular it runs 'git rev-list HEAD --not origin/master',
	# which errors because origin/master is not known. (FIXME: correct message)
	#
	# Probably related to how git-r3.eclass clones the repo.
	#
	# Not sure how fatal that is, but the generated version.h file consists
	# of a single "const char * version = ..." line, so just create version.h
	# here.
	read -r version < ./VERSION && [[ -n "${version}" ]] || die
	printf 'const char * version = "%s";' "${version}-git" > ./version.h || die

	default
}

src_configure() {
	if ! use system-picosat; then
		# bundled picosat
		#  : picosat's configure is not compatible with econf
		#  : if we do not configure picosat here,
		#     emake calls in src_compile() might, and they would pass
		#     empty CFLAGS, resulting in QA check violations due to
		#     "dereferencing type-punned pointer will break strict aliasing"
		( cd "${S}/picosat" && ./configure --static; ) || die
	fi
}

src_compile() {
	if ! use system-picosat; then
		# bundled picosat
		emake -C picosat CFLAGS="${CPPFLAGS} -DNDEBUG ${CFLAGS} -static" \
			libpicosat.a picosat picomus
	fi

	# the {C{,XX,PP},LD}FLAGS might seem a bit unnecessary here,
	# but otherwise the settings from make.conf would be ignored.
	# Additionally, this allows to unbundle picosat.
	emake -C undertaker \
		CPPFLAGS="${CPPFLAGS} -I../scripts/kconfig" \
		CFLAGS="${CFLAGS}" \
		CXXFLAGS="${CXXFLAGS} -std=gnu++11" \
		LDFLAGS="${LDFLAGS}" \
		LOCALPICOSAT="$(usex system-picosat "" ../picosat)" \
		satyr
}

src_install() {
	dobin undertaker/${PN}
	if ! use system-picosat; then
		newbin picosat/picosat ${PN}-picosat
		newbin picosat/picomus ${PN}-picomus
	fi
}
