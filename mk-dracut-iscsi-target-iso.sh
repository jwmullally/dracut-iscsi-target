#!/bin/bash
set -eux -o pipefail

. /etc/dracut.conf.d/iscsi-target.conf

ROOTDIR="$(mktemp -d)"
cp -r /usr/share/syslinux "$ROOTDIR/isolinux"

cat > "$ROOTDIR/isolinux/isolinux.cfg" << EOF
DEFAULT linux
PROMPT 1
TIMEOUT 30
LABEL linux
 KERNEL vmlinuz
 APPEND initrd=initrd.img $dracut_iscsi_target_client_kernelargs
EOF

cp "/boot/vmlinuz-$(uname -r)" "$ROOTDIR/isolinux/vmlinuz"
cp "/boot/initramfs-$(uname -r).img" "$ROOTDIR/isolinux/initrd.img"

mkisofs \
    -b isolinux/isolinux.bin \
    -c isolinux/boot.cat \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    -eltorito-alt-boot \
    -o iscsi-boot.iso \
    "$ROOTDIR"
isohybrid iscsi-boot.iso

rm -rf "$ROOTDIR/isolinux"
rmdir "$ROOTDIR"
