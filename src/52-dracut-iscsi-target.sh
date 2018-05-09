#!/bin/bash
set -eu -o pipefail

export LANG=C

KERNEL_VERSION="$1"
KERNEL_IMAGE="$2"

INITRDFILE="/boot/initramfs-${KERNEL_VERSION}.img"

[[ -f $KERNEL_IMAGE ]] || exit 1
[[ -f $INITRDFILE ]] || exit 1

NEW_KERNEL_IMAGE="/boot/vmlinuz-iscsi-target"
NEW_INITRDFILE="/boot/initramfs-iscsi-target.img"

[[ -f /etc/os-release ]] && . /etc/os-release
[[ -f /etc/dracut.conf.d/iscsi-target.conf ]] && . /etc/dracut.conf.d/iscsi-target.conf

[[ $dracut_iscsi_target_bootentries != "yes" ]] && exit 0

cp --reflink=auto "$KERNEL_IMAGE" "$NEW_KERNEL_IMAGE"
cp --reflink=auto "$INITRDFILE" "$NEW_INITRDFILE"

new-kernel-pkg \
    --install iscsi-target \
    --kernel-image "$NEW_KERNEL_IMAGE" \
    --initrdfile "$NEW_INITRDFILE" \
    --banner "$NAME $VERSION_ID" \
    --kernel-args "$dracut_iscsi_target_kernelargs"

new-kernel-pkg \
    --update iscsi-target \
    --kernel-image "$NEW_KERNEL_IMAGE" \
    --initrdfile "$NEW_INITRDFILE" \
    --banner "$NAME $VERSION_ID" \
    --remove-args "$dracut_iscsi_target_kernelargs_remove"
