# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

EGIT_REPO_URI="git://github.com/dywisor/kernelconfig.git
	https://github.com/dywisor/kernelconfig.git"

inherit git-2

DESCRIPTION="Hardware info collector script for kernelconfig"
HOMEPAGE="https://github.com/dywisor/kernelconfig"
SRC_URI=""

LICENSE="GPL-2"
SLOT="0"
KEYWORDS=""
IUSE=""

DEPEND=""
RDEPEND=""

src_compile() { :; }

src_install() {
	newbin files/scripts/hwcollect.sh "${PN}"
}
