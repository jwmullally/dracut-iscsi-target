PKG=dracut-iscsi-target
VER=0.3

all: ;

install:
	install -m 0755 -D -t $(DESTDIR)/usr/lib/dracut/modules.d/95iscsi-target src/module-setup.sh
	install -m 0755 -D -t $(DESTDIR)/usr/lib/dracut/modules.d/95iscsi-target src/iscsi-target.sh
	install -m 0755 -D -t $(DESTDIR)/etc/kernel/postinst.d src/52-dracut-iscsi-target.sh
	install -m 0600 -D -t $(DESTDIR)/etc/dracut.conf.d/ src/iscsi-target.conf
	install -m 0755 -D -t $(DESTDIR)/usr/sbin/ src/mk-dracut-iscsi-target-iso.sh

regen:
	/bin/kernel-install add $(shell uname -r) /lib/modules/$(shell uname -r)/vmlinuz
	mk-dracut-iscsi-target-iso.sh

srpm: clean
	mkdir -p rpmbuild/SOURCES
	tar --transform "s;^./;${PKG}-${VER}/;" \
		--exclude='./.git' --exclude='./rpmbuild' \
		-zcvf rpmbuild/SOURCES/${PKG}-${VER}.tar.gz ./
	rpmbuild --define "_topdir $(shell pwd)/rpmbuild/" --undefine "dist" \
		-bs ${PKG}.spec

clean:
	rm -rf rpmbuild iscsi-boot.iso test/iscsi-boot.iso
