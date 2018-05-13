#!/bin/sh
set -ex

export SSHPASS=fedora
sshopts="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
target_ip="$(virsh --quiet -c qemu:///system domifaddr test-target | tail -n1 | awk '{print $4}' | cut -d'/' -f1)"
run_cmd="sshpass -e ssh $sshopts root@$target_ip"

(cd .. &&
    make srpm &&
    rpmbuild --define "_topdir $(pwd)/rpmbuild/" --undefine "dist" --rebuild rpmbuild/SRPMS/*)

if $run_cmd rpm -q dracut-iscsi-target; then
    $run_cmd dnf remove -y --noautoremove dracut-iscsi-target
fi
$run_cmd rm -f dracut-iscsi-target-*.rpm

sshpass -e scp $sshopts $(find ../rpmbuild/RPMS/ -type f) "root@$target_ip:"
$run_cmd dnf install -y dracut-iscsi-target-*.rpm
$run_cmd sed -i 's/^#//' /etc/dracut.conf.d/iscsi-target.conf
$run_cmd /bin/kernel-install add "\$(uname -r)" "/lib/modules/\$(uname -r)/vmlinuz"
$run_cmd mk-dracut-iscsi-target-iso.sh
sshpass -e scp $sshopts "root@$target_ip:iscsi-boot.iso" .
