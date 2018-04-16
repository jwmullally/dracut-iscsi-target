#!/bin/bash
set -e -o pipefail

export LANG=C

KERNEL_VERSION="$1"
KERNEL_IMAGE="$2"

INITRDFILE="/boot/initramfs-${KERNEL_VERSION}.img"

[[ -f $KERNEL_IMAGE ]] || exit 1
[[ -f $INITRDFILE ]] || exit 1

[[ -f /etc/os-release ]] && . /etc/os-release
[[ -f /etc/dracut.conf.d/iscsi-target.conf ]] && . /etc/dracut.conf.d/iscsi-target.conf

[[ $dracut_iscsi_target_bootentries != "yes" ]] && exit 0

new-kernel-pkg \
    --install "$KERNEL_VERSION" \
    --kernel-image "$KERNEL_IMAGE" \
    --initrdfile "$INITRDFILE" \
    --banner "$NAME $VERSION_ID iSCSI Target" \
    --kernel-args="$dracut_iscsi_target_kernelargs"
