PREFIX := "/usr"
SYSCONFDIR := "/etc"

all: rpm;

install:
	install -m 0755 -D -t $(DESTDIR)$(PREFIX)/lib/dracut/modules.d/95iscsi-target src/module-setup.sh
	install -m 0755 -D -t $(DESTDIR)$(PREFIX)/lib/dracut/modules.d/95iscsi-target src/iscsi-target.sh
	install -m 0755 -D -t $(DESTDIR)$(PREFIX)/lib/kernel/install.d src/60-dracut-iscsi-target.install
	install -m 0600 -D -t $(DESTDIR)$(SYSCONFDIR)/dracut.conf.d/ src/iscsi-target.conf

regen:
	/bin/kernel-install --verbose add "$(shell uname -r)" "/lib/modules/$(shell uname -r)/vmlinuz"

rpm: clean
	mkdir -p build
	rpkg local --outdir "$(PWD)/build"

clean:
	rm -rf build
