# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI="6"

EGIT_REPO_URI="https://i4gerrit.informatik.uni-erlangen.de/undertaker"

PYTHON_COMPAT=( python2_7 )
DISTUTILS_OPTIONAL=1

inherit git-r3 distutils-r1

DESCRIPTION="examine and evaluate CPP based source files"
HOMEPAGE="http://vamos.informatik.uni-erlangen.de/trac/undertaker"
SRC_URI=""

# undertaker is GPL-3+, scripts/ is GPL-2, bundled picosat is MIT
LICENSE="GPL-3+ GPL-2 MIT"
SLOT="0"
IUSE="+python"

KEYWORDS=""

_CDEPEND="
	>=dev-libs/boost-1.53
	sys-libs/ncurses:=
	python? ( ${PYTHON_DEPS} )
"
DEPEND="${_CDEPEND}
	dev-cpp/AspectC++[libpuma]
	dev-cpp/pstreams
"
RDEPEND="${_CDEPEND}"
REQUIRED_USE="python? ( ${PYTHON_REQUIRED_USE} )"

src_prepare() {
	local version
	local -a PATCHES=(
		# dev-cpp/pstreams installs its header as pstream.h,
		# undertaker assumes pstreams/pstream.h
		"${FILESDIR}/undertaker-fix-pstream-include.patch"
		# undertaker unconditionally installs python files,
		# and runs "python setup.py build" during "make install"
		"${FILESDIR}/undertaker-Makefile-no-python.patch"
	)

	# generate-version.sh produces some git errors, but succeeds.
	# In particular it runs 'git rev-list HEAD --not origin/master',
	# which errors because origin/master is not known. (FIXME: correct message)
	#
	# Not sure how fatal that is, but the generated version.h file consists
	# of a single "const char * version = ..." line, so just create version.h
	# here.
	read -r version < ./VERSION && [[ -n "${version}" ]] || die
	printf 'const char * version = "%s";' "${version}-git" > ./version.h || die

	if use python; then
		distutils-r1_src_prepare
		# , which in turn calls default
	else
		default
	fi
}

src_configure() {
	# bundled picosat
	#  : picosat's configure is not compatible with econf
	#  : if we do not configure picosat here,
	#     emake calls in src_compile() might, and they would pass
	#     empty CFLAGS, resulting in QA check violations due to
	#     "dereferencing type-punned pointer will break strict aliasing"
	( cd "${S}/picosat" && ./configure --static -O; ) || die

	use python && distutils-r1_src_configure
}

src_compile() {
	# FIXME: Makefile does not pass C[XX]FLAGS around

	# bundled picosat
	emake -C picosat

	emake

	use python && distutils-r1_src_compile
}

src_test() {
	use python && distutils-r1_src_test
}

src_install() {
	# this section is a big TODO
	# * undertaker's scripts and python modules perform file lookups
	#   relative to the path of the executable being run,
	#   expecting a fixed directory structure
	# * some python scripts add <...>/lib/pythonX.Y/site-packages to sys.path
	#   (not an issue to be solved in src_install())
	# * some of the installed files have too generic names (e.g. bin/fakecc),
	#   others need a proper location (e.g. lib/Makefile.list)
	#
	# * the Makefile's install target installs *everything*,
	#   including tailor's ubuntu-related upstart scripts
	#
	# For now, install binaries and libraries to /opt/undertaker
	local opt_dir=/opt/${PN}
	local mydistutilsargs=( "--install-scripts=${opt_dir}/bin" )

	use python && distutils-r1_src_install

	emake \
		DESTDIR="${D}" PREFIX=/usr \
		BINDIR="${opt_dir}/bin" \
		SBINDIR="${opt_dir}/sbin" \
		LIBDIR="${opt_dir}/lib" \
		ETCDIR=/etc \
		install
}
