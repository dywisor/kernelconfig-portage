# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI="5"
K_NOUSENAME="yes"
K_NOSETEXTRAVERSION="yes"
K_SECURITY_UNSUPPORTED="1"
ETYPE="sources"
inherit kernel-2 toolchain-funcs
detect_version

DESCRIPTION="Full sources for the Linux kernel"
HOMEPAGE="https://www.kernel.org https://github.com/dywisor/kernelconfig"
KERNELCONFIG_MODALIAS_MK_VER="94bdde18ed1c22f3d74e7bcd70109613851cf226"
SRC_URI="
	${KERNEL_URI}
	https://raw.githubusercontent.com/dywisor/kernelconfig/${KERNELCONFIG_MODALIAS_MK_VER}/files/data/scripts/modalias.mk -> ${PN}_${KERNELCONFIG_MODALIAS_MK_VER}.mk
"

KEYWORDS=""
IUSE="defconfig"

KERNELCONFIG_MODALIAS_BUILD_DIR="${WORKDIR}/${PN}.build"

pkg_setup() {
	kernel-2_pkg_setup
	export ARCH="$(tc-arch-kernel)"
}

src_unpack() {
	kernel-2_src_unpack

	mkdir -p "${KERNELCONFIG_MODALIAS_BUILD_DIR}" || die
	cp \
		"${DISTDIR}/${PN}_${KERNELCONFIG_MODALIAS_MK_VER}.mk" \
		"${KERNELCONFIG_MODALIAS_BUILD_DIR}/modalias.mk" || die
}

src_compile() {
	local -a kernelconfig_makeopts

	kernel-2_src_compile

	kernelconfig_makeopts=(
		-C "${KERNELCONFIG_MODALIAS_BUILD_DIR}"
		-f "${KERNELCONFIG_MODALIAS_BUILD_DIR}/modalias.mk"
		KSRC="${S}"
	)
	# avoid repoman false positives ("assignment to read-only variable")
	kernelconfig_makeopts+=( T="${KERNELCONFIG_MODALIAS_BUILD_DIR}/build" )
	kernelconfig_makeopts+=( D="${KERNELCONFIG_MODALIAS_BUILD_DIR}/out" )

	if use defconfig; then
		kernelconfig_makeopts+=( KERNELCONFIG_CONFTARGET=defconfig )
	fi

	# build modules, create modalias info file
	emake "${kernelconfig_makeopts[@]}" compress-modalias

	# and put it in the output directory (out/data.txz)
	emake "${kernelconfig_makeopts[@]}" install-tar
}

src_install() {
	insinto "/usr/share/${PN%%-*}/modalias"
	newins \
		"${KERNELCONFIG_MODALIAS_BUILD_DIR}/out/data.txz" \
		"${PV}__${ARCH}.txz"  # $ARCH has been exported before
}

# override kernel-2.eclass phase functions with no-op
src_test() { :; }
pkg_preinst() { :; }
pkg_postinst() { :; }
pkg_postrm() { :; }
