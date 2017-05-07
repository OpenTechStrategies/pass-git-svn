PROG:=pass-git-svn
BIN:=git-svn.bash
HOMEPAGE:=https://github.com/OpenTechStrategies/pass-git-svn
GIT:=https://github.com/OpenTechStrategies/pass-git-svn.git
GIT_BROWSE:=https://github.com/OpenTechStrategies/pass-git-svn
SHORT_DESCRIPTION:=pass extension to enable use of svn repositories
LONG_DESCRIPTION:="This is an extension to the [standard linux password]\\n manager \(https://www.passwordstore.org/\) that allows passwords to\\n back up to an svn repository instead of a git repository.  This\\n	extension does that by using git-svn."

VERSION:=$(shell git describe --tags | sed "s/-/./" | sed "s/-.*//")

BASENAME:=${PROG}-${VERSION}
DEBNAME:=${PROG}_${VERSION}-1_all.deb
DEBFOLDERNAME:=build/deb/${BASENAME}
TARNAME:=${PROG}_${VERSION}
TARFOLDERNAME:=build/tar/${TARNAME}

all: distrib

distrib: targz deb

deb: distrib/${DEBNAME}

distrib/${DEBNAME}: git-svn.bash Makefile
	@mkdir -p ${DEBFOLDERNAME}
	@mkdir -p distrib
	@cp ${BIN} ${DEBFOLDERNAME}
	@cd ${DEBFOLDERNAME}; \
		DEBFULLNAME="James Vasile" \
		DEBEMAIL="james@jamesvasile.com" \
		dh_make -y -i -c gpl3 --createorig; \
		echo ${BIN} /usr/lib/password-store/extensions > debian/install 
	@./git-svn.bash | go-md2man > ${DEBFOLDERNAME}/debian/manpage.1
	@scripts/git2changelog > ${DEBFOLDERNAME}/debian/changelog
	@cd ${DEBFOLDERNAME}/debian; \
		rm -f *.ex *.EX README.*; \
		echo "" > ${PROG}-docs.docs; \
		sed -i "s!^Section: .*!Section: admin!" control; \
		sed -i "s!^Homepage: .*!Homepage: ${HOMEPAGE}!" control; \
		sed -i "s!^\\#Vcs-Git: .*!Vcs-Git: ${GIT}!" control; \
		sed -i "s!^\\#Vcs-Browser: .*!Vcs-Browser: ${GIT_BROWSE}!" control; \
		sed -i "s!^Description: .*!Description: ${SHORT_DESCRIPTION}!" control; \
		sed -i "s!^Depends: !Depends: git-svn, pass (>= 1.7.1), !" control; \
		sed -i '$$ d' control; \
		echo " ${LONG_DESCRIPTION}" >> control; \
		sed -i "s!^Source: .*!Source: ${GIT_BROWSE}!" copyright; \
		sed -i "s!^Copyright: .*!Copyright:  2017 James Vasile <james@jamesvasile.com>!" copyright; \
		sed -i "/likewise for another author/d" copyright; \
		sed -i "/^\\#.*/d" copyright;
	@cd ${DEBFOLDERNAME}; \
		debuild -uc -us
	@mv build/deb/${PROG}*.deb distrib

targz: distrib/${TARNAME}.tar.gz

distrib/%.tar.gz: distrib/%.tar Makefile
	@rm -f $@
	@gzip -k $<

tar: distrib/${TARNAME}.tar

distrib/${TARNAME}.tar: git-svn.bash Makefile
	@mkdir -p ${TARFOLDERNAME}
	@mkdir -p distrib
	@./git-svn.bash > README.mdwn
	@cp git-svn.bash README.mdwn ${TARFOLDERNAME}
	@scripts/git2changelog > ${TARFOLDERNAME}/changelog
	@git describe --tags	> ${TARFOLDERNAME}/VERSION
	@cd build/tar; tar -c -f ../../distrib/${TARNAME}.tar ${TARNAME}


clean:
	@rm -rf distrib build

.PHONY: distrib
