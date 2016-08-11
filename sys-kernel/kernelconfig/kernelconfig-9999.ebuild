# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

PYTHON_COMPAT=( python{3_3,3_4,3_5} )

EGIT_REPO_URI="git://github.com/dywisor/kernelconfig.git
	https://github.com/dywisor/kernelconfig.git"

DOCS=( doc/rst/{userguide,devguide}.rst )

inherit git-2 distutils-r1

DESCRIPTION="Automated creation of kernel configuration files"
HOMEPAGE="https://github.com/dywisor/kernelconfig"
SRC_URI=""

LICENSE="GPL-2"
SLOT="0"
KEYWORDS=""
IUSE=""

DEPEND=""
RDEPEND="
	virtual/python-enum34[${PYTHON_USEDEP}]
	dev-python/ply[${PYTHON_USEDEP}]
	dev-python/toposort[${PYTHON_USEDEP}]
	sys-apps/portage[${PYTHON_USEDEP}]
	sys-apps/kmod[${PYTHON_USEDEP}]
	dev-python/beautifulsoup:4[${PYTHON_USEDEP}]
	dev-python/lxml[${PYTHON_USEDEP}]
	dev-vcs/git"

pkg_setup() {
	declare -ga KERNELCONFIG_MAKEARGS=(
		PREFIX="/usr"
		SYSCONFDIR="/etc"
		LOCALSTATEDIR="/var"
	)
	declare -gx LKCONFIG_LKC="src/lkc-bundled"
}

python_configure() {
	emake "${KERNELCONFIG_MAKEARGS[@]}" prepare-installinfo
}

python_install_all() {
	distutils-r1_python_install_all

	emake "${KERNELCONFIG_MAKEARGS[@]}" DESTDIR="${D}" install-{config,data}
}
