# Copyright 1999-2018 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit toolchain-funcs

DESCRIPTION="An enhanced (world's fastest) tar, as well as enhanced mt/rmt"
HOMEPAGE="http://s-tar.sourceforge.net/"
SRC_URI="mirror://sourceforge/s-tar/${P}.tar.bz2"

LICENSE="GPL-2 LGPL-2.1 CDDL-Schily"
SLOT="0"
KEYWORDS="amd64"
IUSE="acl xattr"

DEPEND="
	sys-libs/libcap
	acl? ( sys-apps/acl )
	xattr? ( sys-apps/attr )"
RDEPEND="${DEPEND}"

S="${WORKDIR}/${P/_alpha[0-9][0-9]}"

src_prepare() {
	default

	find -type f -exec chmod -c u+w '{}' + || die
	sed \
		-e "s:/opt/schily:${EPREFIX}/usr:g" \
		-e 's:bin:root:g' \
		-e "s:/usr/src/linux/include:${EPREFIX}/usr/include:" \
		-i DEFAULTS/Defaults.linux || die

	eapply "${FILESDIR}/schily-20190715-xattr.patch"
}

src_configure() { :; } #avoid ./configure run

src_compile() {
	emake \
		GMAKE_NOWARN="true" \
		CC="$(tc-getCC)" \
		COPTX="${CFLAGS}" \
		CPPOPTX="${CPPFLAGS}" \
		COPTGPROF= \
		COPTOPT= \
		LDOPTX="${LDFLAGS}"
}

src_install() {
	# Joerg Schilling suggested to integrate star into the main OS using call:
	# make INS_BASE=/usr DESTDIR="${D}" install

	dobin \
		star/OBJ/*-gcc/star \
		tartest/OBJ/*-gcc/tartest \
		star_sym/OBJ/*-gcc/star_sym \
		mt/OBJ/*-gcc/smt


	newsbin rmt/OBJ/*-gcc/rmt rmt.star
	newman rmt/rmt.1 rmt.star.1

	# Note that we should never install gnutar, tar or rmt in this package.
	# tar and rmt are provided by app-arch/tar. gnutar is not compatible with
	# GNU tar and breakes compilation, or init scripts. bug #33119
	dosym {star,/usr/bin/ustar}
	dosym {star,/usr/bin/spax}
	dosym {star,/usr/bin/scpio}
	dosym {star,/usr/bin/suntar}

	#  match is needed to understand the pattern matcher, if you wondered why ;)
	doman man/man1/match.1 tartest/tartest.1 \
		star/{star.4,star.1,spax.1,scpio.1,suntar.1} mt/smt.1

	insinto /etc/default
	newins star/star.dfl star
	newins rmt/rmt.dfl rmt

	dodoc star/{README.ACL,README.crash,README.largefiles,README.otherbugs} \
		star/{README.pattern,README.pax,README.posix-2001,README,STARvsGNUTAR} \
			rmt/default-rmt.sample TODO AN-* Changelog CONTRIBUTING
}
