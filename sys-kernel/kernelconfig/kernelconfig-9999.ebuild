# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

PYTHON_COMPAT=( python{3_3,3_4,3_5} )

EGIT_REPO_URI="git://github.com/dywisor/kernelconfig.git
	https://github.com/dywisor/kernelconfig.git"

inherit git-2 distutils-r1 bash-completion-r1

DESCRIPTION="Automated creation of kernel configuration files"
HOMEPAGE="https://github.com/dywisor/kernelconfig"
SRC_URI=""

LICENSE="GPL-2"
SLOT="0"
KEYWORDS=""
IUSE="html doc-pdf"

DEPEND="html? ( dev-python/docutils ) doc-pdf? ( dev-python/rst2pdf )"
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

	declare -ga DOCS=()
	declare -ga HTML_DOCS=()

	if use doc-pdf; then
		DOCS+=( doc/pdf/{userguide,devguide}.pdf )
	fi

	# .html doc files are always installed,
	# the USE flag controls whether they are rebuilt during src_compile()
	HTML_DOCS+=( doc/html/{userguide,devguide}.html )
}

python_configure() {
	emake "${KERNELCONFIG_MAKEARGS[@]}" prepare-installinfo
}

python_compile_all() {
	emake "${KERNELCONFIG_MAKEARGS[@]}" \
		bashcomp \
		$(usex html htmldoc "") \
		$(usex doc-pdf pdfdoc "")
}

python_install_all() {
	distutils-r1_python_install_all

	emake "${KERNELCONFIG_MAKEARGS[@]}" DESTDIR="${D}" install-{config,data}
	newbashcomp "build/${PN}.bashcomp" "${PN}"
}
