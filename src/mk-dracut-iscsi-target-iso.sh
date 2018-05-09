#!/bin/bash
set -eux -o pipefail

. /etc/dracut.conf.d/iscsi-target.conf

ISOROOT="$(mktemp -d)"
cp -r /usr/share/syslinux "$ISOROOT/isolinux"

cat > "$ISOROOT/isolinux/isolinux.cfg" << EOF
UI menu.c32
DEFAULT linux-iscsi
PROMPT 1
TIMEOUT 50
LABEL linux-iscsi
 KERNEL vmlinuz
 APPEND initrd=initrd.img $dracut_iscsi_target_client_kernelargs
EOF

cp /boot/vmlinuz-iscsi-target "$ISOROOT/isolinux/vmlinuz"
cp /boot/initramfs-iscsi-target.img "$ISOROOT/isolinux/initrd.img"

mkisofs \
    -b isolinux/isolinux.bin \
    -c isolinux/boot.cat \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    -eltorito-alt-boot \
    -o iscsi-boot.iso \
    "$ISOROOT"
isohybrid iscsi-boot.iso

rm -rf "$ISOROOT/isolinux"
rmdir "$ISOROOT"
