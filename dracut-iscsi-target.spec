Name:           dracut-iscsi-target
Version:        0.3
Release:        1%{?dist}
Summary:        dracut module to run as an iSCSI Target instead of booting
License:        MIT
URL:            https://github.com/jwmullally/dracut-iscsi-target
BuildArch:      noarch
Source0:        %{name}-%{version}.tar.gz

Requires:       dracut
Requires:       dracut-network
Requires:       syslinux
Requires:       genisoimage
Requires:       iscsi-initiator-utils


%description
This dracut module allows the initramfs to start as an iSCSI Target
instead of doing a regular boot.

This allows you to run the OS on another host using "netroot=iscsi:...".
For example, you can run your laptop's OS on your desktop without having
to install and maintain a seperate copy.


%prep
%autosetup


%install
make install DESTDIR=%{buildroot}


%files
%defattr(-,root,root,0755)
%doc README.md
%doc LICENCE.txt
%dir /usr/lib/dracut/modules.d/95iscsi-target
/usr/lib/dracut/modules.d/95iscsi-target/module-setup.sh 
/usr/lib/dracut/modules.d/95iscsi-target/iscsi-target.sh 
/etc/kernel/postinst.d/52-dracut-iscsi-target.sh
/usr/sbin/mk-dracut-iscsi-target-iso.sh
%attr(0600,root,root) %config(noreplace) /etc/dracut.conf.d/iscsi-target.conf 


%changelog
* Wed May 9 2018 Joseph Mullally <jwmullally@gmail.com>
- Improve handling of kernel upgrades

* Mon May 7 2018 Joseph Mullally <jwmullally@gmail.com>
- Add CHAP one-way authentication

* Tue Apr 3 2018 Joseph Mullally <jwmullally@gmail.com>
- Initial package
