# Makefile for GNU Emacs.app Modified

# Copyright (C) 2009 Vincent Goulet

# Author: Vincent Goulet

# This file is part of GNU Emacs.app Modified
# http://vgoulet.act.ulaval.ca/emacs

# This Makefile will create a disk image to distribute the software.
# The code is based on a Makefile created by Remko Troncon
# (http://el-tramo.be/about).

include ./Makeconf

TMPDIR=${CURDIR}/tmpdir
TMPDMG=${CURDIR}/tmpdmg.dmg
EMACSDIR=${TMPDIR}/Emacs.app
PREFIX=${EMACSDIR}/Contents

BINARIES=`find ${CURDIR}/emacs-${EMACSVERSION}/nextstep/Emacs.app/Contents/MacOS \
	-type f | xargs file | grep Mach-O | cut -d : -f 1 | cut -d / -f 11-12`
SYMLINKS=`find ${CURDIR}/emacs-${EMACSVERSION}/nextstep/Emacs.app/Contents/MacOS/bin \
	-type l | cut -d / -f 11-12`

TARGET="10.4"
CFLAGS="-arch ${ARCH}"
LDFLAGS="-arch ${ARCH}"

ESS=`ls -d ess-*`
AUCTEX=`ls -d auctex-*`

all : emacs.app emacs ess auctex dmg

.PHONY : emacs.app emacs dir ess auctex dmg clean

emacs.app :
	@echo ----- Building Emacs.app...
	cd emacs-${EMACSVERSION} && \
		env LC_ALL=C LANG=C CFLAGS=${CFLAGS} LDFLAGS=${LDFLAGS} \
		MACOSX_DEPLOYMENT_TARGET=${TARGET} \
		./configure --with-ns
	${MAKE} -C emacs-${EMACSVERSION} clean
	env MACOSX_DEPLOYMENT_TARGET=${TARGET} \
		${MAKE} -C emacs-${EMACSVERSION} install

emacs : dir ess auctex dmg

dir :
	@echo ----- Creating the application in temporary directory...
	if [ -d ${TMPDIR} ]; then rm -rf ${TMPDIR}; fi
	ditto -rsrc ${CURDIR}/emacs-${EMACSVERSION}/nextstep/Emacs.app/ \
		${EMACSDIR}
	ditto -rsrc ${CURDIR}/Emacs.app-${OTHERARCH}/Contents/MacOS/ \
		${PREFIX}/MacOS-${OTHERARCH}
	mv ${PREFIX}/MacOS ${PREFIX}/MacOS-${ARCH}
	mkdir -p ${PREFIX}/MacOS/bin ${PREFIX}/MacOS/libexec
	cd ${PREFIX} && echo ${BINARIES} | xargs -n1 -I % \
		lipo -create MacOS-${ARCH}/%              \
		             MacOS-${OTHERARCH}/%         \
		     -output MacOS/%
	cd ${PREFIX} && echo ${SYMLINKS} | xargs -n1 -I % \
		cp -pR MacOS-i386/% MacOS/%
	rm -rf ${PREFIX}/MacOS-*
	cp -p site-start.el ${PREFIX}/Resources/site-lisp/
	cp -p psvn.el ${PREFIX}/Resources/site-lisp/
	cp -p fixpath.el ${PREFIX}/Resources/site-lisp/
	cp -p Emacs.icns ${PREFIX}/Resources/
	cp -p emacs-document.icns ${PREFIX}/Resources/

ess : 
	@echo ----- Making ESS...
	cp -p ${ESS}/Makeconf ${ESS}/Makeconf.orig
	sed -i "" '/^DESTDIR/s|/usr/local|'${PREFIX}'/Resources|' \
		${ESS}/Makeconf
	sed -i "" '/^EMACS/s|emacs|'${PREFIX}'/MacOS/Emacs|' ${ESS}/Makeconf
	sed -i "" '/^LISPDIR/s/share\/emacs\/site-lisp/site-lisp\/ess/' \
		${ESS}/Makeconf
	sed -i "" '/^ETCDIR/s/share\/emacs\///'  ${ESS}/Makeconf
	sed -i "" '/^DOCDIR/s/share\///' ${ESS}/Makeconf
	${MAKE} -C ${ESS} all 
	${MAKE} -C ${ESS} install
	@echo ----- Done making ESS

auctex :
	@echo ----- Making AUCTeX...
	cd ${AUCTEX} && ./configure --datarootdir=${PREFIX}/Resources \
		--without-texmf-dir \
		--with-lispdir=${PREFIX}/Resources/site-lisp \
		--with-emacs=${PREFIX}/MacOS/Emacs
	make -C ${AUCTEX}
	make -C ${AUCTEX} install
	@echo ----- Done making AUCTeX

dmg : 
	@echo ----- Creating disk image...
	if [ -e ${TMPDMG} ]; then rm ${TMPDMG}; fi
	hdiutil create ${TMPDMG} \
		-size 130m \
	 	-format UDRW \
		-fs HFS+ \
		-srcfolder ${TMPDIR} \
		-volname ${DISTNAME} \
		-quiet

	@echo ----- Mounting disk image...
	hdiutil attach ${TMPDMG} -noautoopen -quiet

	@echo ----- Populating top level image directory...
	cp -p README.txt ${VOLUME}/${DISTNAME}/
	cp -p NEWS ${VOLUME}/${DISTNAME}/
	cp -R Applications ${VOLUME}/${DISTNAME}/

	@echo ----- Unmounting and compressing disk image...
	hdiutil detach ${VOLUME}/${DISTNAME} -quiet
	if [ -e ${DISTNAME}.dmg ]; then rm ${DISTNAME}.dmg; fi
	hdiutil convert ${TMPDMG} \
		-format UDZO \
		-imagekey zlib-level=9 \
		-o ${DISTNAME}.dmg -quiet

	rm -rf ${TMPDIR} ${TMPDMG}
	@echo ----- Done building the disk image

clean :
	rm ${DISTNAME}.dmg
	cd emacs-${EMACSVERSION} && ${MAKE} clean
	cd ${ESS} && ${MAKE} clean
	cd ${AUCTEX} && ${MAKE} clean