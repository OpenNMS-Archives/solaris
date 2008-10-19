#
#   $Id$
#
# Copyright (c) 1999, 2008 Daniel J. Gregor, Jr., All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY DANIEL J. GREGOR, JR. ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL DANIEL J. GREGOR, JR. BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#
# Homepage for OpenNMS:
#	http://www.opennms.org/
#
# You can get the source at:
#	XXX fill this in XXX
#

TOPONMSDIR:sh= cd .. ; pwd
OPENNMSTGZSH = ls ${TOPONMSDIR}/target/opennms-*.tar.gz
OPENNMSTGZ   = ${OPENNMSTGZSH:sh}

#SRCVERSIONSH= echo ${OPENNMSTGZ} | sed -e 's/.*opennms-//' -e 's/\.tar\.gz//'
SRCVERSIONSH= echo ${OPENNMSTGZ} | sed -e 's/.*\///' -e 's/\.tar\.gz//'
SRCVERSIONSHORT  = ${SRCVERSIONSH:sh}
REVISIONSH  = svn info ${TOPONMSDIR} 2> /dev/null | grep Revision: | awk '{ print $$2 }'
REVISION    = ${REVISIONSH:sh}
REVISIONDASH= if [ x"${REVISION}" = x"" -o x"`echo ${SRCVERSIONSHORT} | grep SNAPSHOT`" = x"" ]; then echo ""; else echo "-${REVISION}"; fi
SRCVERSION  = ${SRCVERSIONSHORT}${REVISIONDASH:sh}
BUILDDIR    = untar

DESTDIR     = ${TOPDIR}/pkg 

BASEDIR     = /opt/opennms
#ETCDIR      = /etc/opt/opennms
BASEDIREXISTS=/opt

CONFOPTS    = 

PKGNAME     = opennms
NAME        = OpenNMS
DESC        = Enterprise-grade open source network management system
ARCH        = all
VERSIONSH1  = echo ${SRCVERSION} | sed -e 's/^[^-]*-//' -e 's/^.*\.v//'
#VERSIONSH2  = uname -s
#VERSIONSH3  = uname -r
VERSION     = ${VERSIONSH1:sh} # (${VERSIONSH2:sh}-${VERSIONSH3:sh})
CATEGORY    = application
MAXINST     = 1000
VENDOR      = The OpenNMS Group
EMAIL       = dj@opennms.org
CLASSES     = none

PKGPROTO    = /usr/bin/pkgproto
PKGMK       = /usr/bin/pkgmk
PKGTRANS    = /usr/bin/pkgtrans

INSTUSER    = opennms
INSTGROUP   = opennms

TOPDIR:sh   = pwd

SPOOLDIR    = /var/spool/pkg

OTHERFILES  = ${DESTDIR}${BASEDIR}/docs/COPYING \
		${DESTDIR}${BASEDIR}/contrib/svc-opennms \
		${DESTDIR}${BASEDIR}/contrib/smf-manifest.xml
INSTALLFILES= ${DESTDIR}/install/pkginfo \
		${DESTDIR}/install/copyright \
		${DESTDIR}/install/depend \
		${DESTDIR}/install/preinstall \
		${DESTDIR}/install/postinstall \
		${DESTDIR}/install/preremove

all: package

package: check pkg

check::
	@echo "Source version: ${SRCVERSION}"
	test -f ${OPENNMSTGZ}

pkg: ${SRCVERSION}.pkg

${SRCVERSION}.pkg:  ${DESTDIR}/prototype
	( cd ${DESTDIR} && ${PKGMK} -d ${SPOOLDIR} -or . )
#	( cd ${SPOOLDIR}/${PKGNAME}/reloc && find . -depth -print | \
#		grep -v '^\.$$' | cpio -odm | compress -f > ../reloc.cpio.Z )
#	rm -rf ${SPOOLDIR}/${PKGNAME}/reloc
	$(PKGTRANS) ${SPOOLDIR} ${TOPDIR}/${SRCVERSION}.pkg ${PKGNAME}

${DESTDIR}/prototype: .package-installed.${SRCVERSION} ${INSTALLFILES}
	@( cd ${DESTDIR} ; \
	 find . -print | \
		$(PKGPROTO) | \
		nawk -v instuser="${INSTUSER}" \
		     -v instgroup="${INSTGROUP}" \
		     -v basedirexists="${BASEDIREXISTS}" \
		'BEGIN { \
			b = split(basedirexists, basedirs); \
		} \
		{ \
			if ( match($$3, "^prototype$$") ) { \
				next; \
 			} \
			if ( match($$3, "^install$$") ) { \
				next; \
 			} \
			if ( match($$3, "^install/") ) { \
			 	base = $$3; \
			 	sub("^.*/", "", base); \
			 	print "i", base "=" $$3; \
				next; \
 			} \
			for ( i = 1; i <= b; i++ ) { \
				checkbasedir = basedirs[i]; \
				sub("^/", "", checkbasedir); \
				while ( checkbasedir != "" ) { \
					if ( match($$3, "^"checkbasedir"$$") ) { \
						sub("[^/]*$$", "", checkbasedir); \
						sub("/$$", "", checkbasedir); \
						print $$1, $$2, $$3, "?", "?", "?"; \
						next; \
	 				} \
					sub("[^/]*$$", "", checkbasedir); \
					sub("/$$", "", checkbasedir); \
				} \
			} \
			\
			print $$1, $$2, $$3, $$4, instuser, instgroup; \
		}' \
	 ) | \
	sed '/ opt /d;/ etc /d;/ etc\/opt /d' | \
	sed 's!\(opt/FSFsudo/bin/sudo\) [0-9][0-9]*!\1 4111!' | \
	sed 's!\(opt/FSFsudo/sbin/visudo\) [0-9][0-9]*!\1 4111!' \
	> ${DESTDIR}/prototype

${DESTDIR}/install: ${DESTDIR}
	mkdir $@

${DESTDIR}/install/pkginfo: ${DESTDIR}/install 
	rm -f $@
	@echo "PKG=\"${PKGNAME}\"" >> $@
	@echo "NAME=\"${NAME}\"" >> $@
	@echo "DESC=\"${DESC}\"" >> $@
	@echo "ARCH=\"${ARCH}\"" >> $@
	@echo "MAXINST=\"${MAXINST}\"" >> $@
	@echo "VERSION=\"${VERSION}\"" >> $@
	@echo "CATEGORY=\"${CATEGORY}\"" >> $@
	@echo "VENDOR=\"${VENDOR}\"" >> $@
	@echo "EMAIL=\"${EMAIL}\"" >> $@
	@echo "BASEDIR=\"/\"" >> $@
	@echo "CLASSES=\"${CLASSES}\"" >> $@

# XXX no java is listed since there are multiple possible package names
${DESTDIR}/install/depend: ${DESTDIR}/install
	rm -f $@
	@echo "P	NMSjicmp	OpenNMS jicmp plugin" >> $@
#	@echo "P	SUNWpostgr-server	The programs needed to create and run a PostgreSQL 8.1.5 server" >> $@
#	@echo "P	SUNWpostgr-pl	The PL procedural languages for PostgreSQL 8.1.5" >> $@

${DESTDIR}/install/preinstall: ${DESTDIR}/install
	rm -f $@
	@echo "#!/bin/sh -" >> $@
	@echo "" >> $@
	@echo "if /usr/bin/getent group opennms > /dev/null; then" >> $@
	@echo "	echo \"opennms group already exists, not adding\"" >> $@
	@echo "else" >> $@
	@echo "	echo \"opennms group does not exist, adding\"" >> $@
	@echo "	/usr/sbin/groupadd opennms" >> $@
	@echo "	if [ \$$? -ne 0 ]; then" >> $@
	@echo "		echo \"Failed to add opennms group, exiting\" >&2" >> $@
	@echo "		exit 1" >> $@
	@echo "	fi" >> $@
	@echo "fi" >> $@
	@echo "" >> $@
	@echo "if /usr/bin/getent passwd opennms > /dev/null; then" >> $@
	@echo "	echo \"opennms user already exists, not adding\"" >> $@
	@echo "else" >> $@
	@echo "	echo \"opennms user does not exist, adding\"" >> $@
	@echo "	/usr/sbin/useradd -g opennms -d /opt/opennms -c \"OpenNMS Daemon\" opennms" >> $@
	@echo "	if [ \$$? -ne 0 ]; then" >> $@
	@echo "		echo \"Failed to add opennms user, exiting\" >&2" >> $@
	@echo "		exit 1" >> $@
	@echo "	fi" >> $@
	@echo "fi" >> $@

${DESTDIR}/install/postinstall: ${DESTDIR}/install
	rm -f $@
	@echo "#!/bin/sh -" >> $@
	@echo "" >> $@
	@echo "rm -f ${BASEDIR}/etc/configured" >> $@
	@echo "" >> $@
	@echo "for distfile in ${BASEDIR}/etc/.dist/*; do" >> $@
	@echo "	basename=\`basename \$$distfile\`" >> $@
	@echo "	if [ -f ${BASEDIR}/etc/\$$basename ]; then" >> $@
	@echo "		cp \$$distfile ${BASEDIR}/etc/\$$basename.rpmnew || exit 1" >> $@
	@echo "	else" >> $@
	@echo "		cp \$$distfile ${BASEDIR}/etc/\$$basename || exit 1" >> $@
	@echo "	fi" >> $@
	@echo "	chown opennms:opennms ${BASEDIR}/etc/\$$basename || exit 1" >> $@
	@echo "done" >> $@
	@echo "" >> $@
	@echo "/usr/sbin/svccfg import ${BASEDIR}/contrib/smf-manifest.xml || exit 1" >> $@
	@echo "" >> $@
	@echo "if [ -f ${BASEDIR}/etc/java.conf ]; then" >> $@
	@echo "	/usr/bin/su ${INSTUSER} -c \"${BASEDIR}/bin/runjava -c\" || exit 1" >> $@
	@echo "else" >> $@
	@echo "	/usr/bin/su ${INSTUSER} -c \"${BASEDIR}/bin/runjava -s\" || exit 1" >> $@
	@echo "fi" >> $@
	@echo "" >> $@
	@echo "/usr/bin/su ${INSTUSER} -c \"${BASEDIR}/bin/install -dis\" || exit 1" >> $@
	@echo "" >> $@
	@echo "/usr/sbin/svcadm enable opennms || exit 1" >> $@

${DESTDIR}/install/preremove: ${DESTDIR}/install
	rm -f $@
	@echo "#!/bin/sh -" >> $@
	@echo "" >> $@
	@echo "/usr/sbin/svcadm disable -s opennms || exit 1" >> $@
	@echo "" >> $@
	@echo "rm -f ${BASEDIR}/etc/configured" >> $@
	@echo "" >> $@
	@echo "# Remove files that haven't changed from the distributed version" >> $@
	@echo "for distfile in ${BASEDIR}/etc/.dist/*; do" >> $@
	@echo "	basename=\`basename \$$distfile\`" >> $@
	@echo "	if cmp -s \$$distfile ${BASEDIR}/etc/\$$basename; then" >> $@
	@echo "		rm ${BASEDIR}/etc/\$$basename" >> $@
	@echo "	fi" >> $@
	@echo "done" >> $@
	@echo "" >> $@
	@echo "/usr/sbin/svccfg delete opennms" >> $@

.package-installed.${SRCVERSION}: build clean.${DESTDIR} ${DESTDIR}${BASEDIR} \
		${OTHERFILES} ${OPENNMSTGZ} # install-docs deejinstall
#	cd ${BUILDDIR} ; ${MAKE} prefix=${DESTDIR}${BASEDIR} \
#		sysconfdir=${DESTDIR}${ETCDIR} \
#		sbindir=${DESTDIR}${BASEDIR}/sbin \
#		INSTALL=${TOPDIR}/deejinstall \
#		install_uid=root install_gid=root \
#		install
#	-( cd ${DESTDIR}/${BASEDIR}/bin ; strip * )
	cd ${DESTDIR}${BASEDIR} && gzip -cd ${OPENNMSTGZ} | gtar xf -
	chmod 755 ${DESTDIR}${BASEDIR}/bin/*
	find ${DESTDIR}${BASEDIR}/logs -name .readme | xargs rm
	find ${DESTDIR}${BASEDIR}/share -name .readme | xargs rm
	rm -rf ${DESTDIR}${BASEDIR}/webapps
	/usr/bin/echo "/^RUNAS=/\\ns/.*/RUNAS=\\\"${INSTUSER}\\\"/\\nw\\nq" | \
		ed ${DESTDIR}${BASEDIR}/bin/opennms
	mkdir ${DESTDIR}${BASEDIR}/etc/.dist
	mv `find ${DESTDIR}${BASEDIR}/etc/* -prune -type f` ${DESTDIR}${BASEDIR}/etc/.dist/.
	touch $@

deejinstall:
	@echo "#!/bin/sh -" >> $@
	@echo "" >> $@
	@echo "basename=\"\`basename \$$0\`\"" >> $@
	@echo "die() {" >> $@
	@echo "        echo \"\$$basename: \$$*\" >&2" >> $@
	@echo "        exit 1" >> $@
	@echo "}" >> $@
	@echo "" >> $@
	@echo "usage=\"\$$basename [-o <owner>] [-g <group>] [-m <mode>] [-s] <source> <dest>\"" >> $@
	@echo "" >> $@
	@echo "strip=0" >> $@
	@echo "" >> $@
	@echo "while getopts o:g:m:s c" >> $@
	@echo "do" >> $@
	@echo "	case \$$c in" >> $@
	@echo "		o)" >> $@
	@echo "			owner=\"\$$OPTARG\"" >> $@
	@echo "		;;" >> $@
	@echo "" >> $@
	@echo "		g)" >> $@
	@echo "			group=\"\$$OPTARG\"" >> $@
	@echo "		;;" >> $@
	@echo "" >> $@
	@echo "		m)" >> $@
	@echo "			mode=\"\$$OPTARG\"" >> $@
	@echo "		;;" >> $@
	@echo "" >> $@
	@echo "		s)" >> $@
	@echo "			strip=1" >> $@
	@echo "		;;" >> $@
	@echo "" >> $@
	@echo "		\\?)" >> $@
	@echo "			die \"What up?\"" >> $@
	@echo "		;;" >> $@
	@echo "	esac" >> $@
	@echo "done" >> $@
	@echo "" >> $@
	@echo "shift \`expr \$$OPTIND - 1\`" >> $@
	@echo "" >> $@
	@echo "if [ \$$# -ne 2 ]; then" >> $@
	@echo "	die \"Usage: \$$usage\"" >> $@
	@echo "fi" >> $@
	@echo "" >> $@
	@echo "source=\"\$$1\"; shift" >> $@
	@echo "dest=\"\$$1\"; shift" >> $@
	@echo "" >> $@
	@echo "cp \"\$$source\" \"\$$dest\" || die \"Could not copy \$$source to \$$dest\"" >> $@
	@echo "" >> $@
	@echo "if [ \$$strip -ne 0 ]; then" >> $@
	@echo "	strip \"\$$dest\" || die \"Could not strip \$$dest\"" >> $@
	@echo "fi" >> $@
	@echo "" >> $@
	@echo "if [ \"\$$owner\"x != \"\"x ]; then" >> $@
	@echo "	chown \"\$$owner\" \"\$$dest\"	# don't care if it fails" >> $@
	@echo "fi" >> $@
	@echo "" >> $@
	@echo "if [ \"\$$group\"x != \"\"x ]; then" >> $@
	@echo "	chgrp \"\$$group\" \"\$$dest\" # don't care if it fails" >> $@
	@echo "fi" >> $@
	@echo "" >> $@
	@echo "if [ \"\$$mode\"x != \"\"x ]; then" >> $@
	@echo "	chmod \"\$$mode\" \"\$$dest\" # don't care if it fails" >> $@
	@echo "fi" >> $@
	@chmod 755 $@


# XXX it should be under BUILDDIR somewhere
#${DESTDIR}${BASEDIR}/docs/COPYING: ${BUILDDIR}/COPYING
${DESTDIR}${BASEDIR}/docs/COPYING: ${DESTDIR}${BASEDIR}/docs ${TOPONMSDIR}/GPL
	cp ${TOPONMSDIR}/GPL $@

${DESTDIR}${BASEDIR}/contrib/svc-opennms: ${DESTDIR}${BASEDIR}/contrib svc-opennms
	cp svc-opennms $@

${DESTDIR}${BASEDIR}/contrib/smf-manifest.xml: ${DESTDIR}${BASEDIR}/contrib smf-manifest.xml
	cp smf-manifest.xml $@

${DESTDIR}${BASEDIR}/contrib: ${DESTDIR}${BASEDIR}
	mkdir $@

${DESTDIR}/install/copyright: ${DESTDIR}/install
	rm -f $@
	@echo "This is free software; you can redistribute it and/or" >> $@
	@echo "modify it under the terms of the GNU General Public" >> $@
	@echo "License, see the file ${BASEDIR}/docs/COPYING." >> $@

clean.${DESTDIR}:
	rm -rf ${DESTDIR}

${DESTDIR}${BASEDIR}:
	mkdir -p ${DESTDIR}${BASEDIR}

build: .configured.${SRCVERSION}
#	cd ${TOPONMSDIR} ; ./build.sh -Dopennms.home=${BASEDIR} install assembly:attached
	true

clean:
	rm -rf ${BUILDDIR} ${DESTDIR} .configured.${SRCVERSION} \
		.untarred.${SRCVERSION} .package-installed.${SRCVERSION} \
		deejinstall ${SPOOLDIR}/${PKGNAME} ${SRCVERSION}.pkg

.untarred.${SRCVERSION}: ${OPENNMSTGZ}
#	rm -rf ${BUILDDIR}
#	mkdir -p ${BUILDDIR}
#	cd ${BUILDDIR} && gzip -cd $? | gtar xvf -
	touch $@

.configured.${SRCVERSION}: .untarred.${SRCVERSION}
#	cd ${BUILDDIR} ; ./configure --prefix=${BASEDIR} \
#		--sysconfdir=${ETCDIR} --sbindir=${BASEDIR}/sbin
#		${CONFOPTS} 
	touch $@

veryclean:
	rm -rf ${BUILDDIR} ${DESTDIR} .configured.${SRCVERSION} \
		.untarred.${SRCVERSION} .package-installed.${SRCVERSION} \
		.revision ${SPOOLDIR}/${PKGNAME} ${SRCVERSION}.pkg


install-docs: ${DESTDIR}${BASEDIR}/docs
#	cd ${BUILDDIR} ; ls -1 [A-Z]* | egrep -v 'Makefile|ChangeLog.zoo' | \
#		cpio -updm ${DESTDIR}${BASEDIR}/docs
	true

${DESTDIR}${BASEDIR}/docs: ${DESTDIR}${BASEDIR}
	mkdir -p ${DESTDIR}${BASEDIR}/docs 

