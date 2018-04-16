#!/bin/sh
set -ex

export SSHPASS=fedora
sshopts="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
target_ip="$(virsh -c qemu:///system domifaddr test-target | awk '{print $4}' | tail -n 2 | head -n 1 | cut -d'/' -f1)"
run_cmd="sshpass -e ssh $sshopts root@$target_ip"

(cd .. &&
    make srpm &&
    rpmbuild --define "_topdir $(pwd)/rpmbuild/" --undefine "dist" --rebuild rpmbuild/SRPMS/*)

sshpass -e scp $sshopts $(find ../rpmbuild/RPMS/ -type f) "root@$target_ip:"
$run_cmd rm -f /etc/dracut.conf.d/iscsi-target.conf dracut-iscsi-target-*.rpm
if $run_cmd rpm -q dracut-iscsi-target; then
    $run_cmd dnf reinstall -y dracut-iscsi-target-*.rpm
else
    $run_cmd dnf install -y dracut-iscsi-target-*.rpm
fi
$run_cmd sed -i 's/^#//' /etc/dracut.conf.d/iscsi-target.conf
$run_cmd /bin/kernel-install remove "\$(uname -r)"
$run_cmd /bin/kernel-install add "\$(uname -r)" "/lib/modules/\$(uname -r)/vmlinuz"
$run_cmd mk-dracut-iscsi-target-iso.sh
sshpass -e scp $sshopts "root@$target_ip:iscsi-boot.iso" .
