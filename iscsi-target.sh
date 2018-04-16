#!/bin/sh

type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh

TARGET='/sys/kernel/config/target'

create_iscsi_target() {
    modprobe -a target_core_mod target_core_iblock iscsi_target_mod
    mkdir "$TARGET/core/iblock_0"
    mkdir "$TARGET/iscsi"
    mkdir "$TARGET/iscsi/$IQN"
    mkdir "$TARGET/iscsi/$IQN/tpgt_1"
    echo 0 > "$TARGET/iscsi/$IQN/tpgt_1/attrib/authentication"
    echo 0 > "$TARGET/iscsi/$IQN/tpgt_1/attrib/demo_mode_write_protect"
    echo 1 > "$TARGET/iscsi/$IQN/tpgt_1/attrib/generate_node_acls"
    if ! mkdir "$TARGET/iscsi/$IQN/tpgt_1/np/[::0]:3260"; then
        die "iscsi-target: Unable to listen on port 3260 for \"$IQN\""
    fi
    if ! echo 1 > "$TARGET/iscsi/$IQN/tpgt_1/enable"; then
        die "iscsi-target: Unable to start \"$IQN\""
    fi
}

next_lun_id() {
    i="$(for d in "$TARGET/iscsi/$IQN/tpgt_1/lun"/*; do echo "$d"; done | grep -o '[0-9]\+$' | sort -n | tail -n 1)"
    echo $((i + 1))
}

add_iscsi_device() {
    DEVICE="$1"
    LUN="$(next_lun_id)"
    mkdir "$TARGET/core/iblock_0/root$LUN"
    echo "$DEVICE" > "$TARGET/core/iblock_0/root$LUN/udev_path"
    echo "udev_path=$DEVICE" > "$TARGET/core/iblock_0/root$LUN/control"
    echo 1 > "$TARGET/core/iblock_0/root$LUN/enable"
    mkdir "$TARGET/iscsi/$IQN/tpgt_1/lun/lun_$LUN"
    if ! ln -s "$TARGET/core/iblock_0/root$LUN" "$TARGET/iscsi/$IQN/tpgt_1/lun/lun_$LUN/link_root$LUN"; then
        die "iscsi-target: Unable to add \"$DEVICE\" to \"$IQN\""
    fi
}

IQN="$(getarg rd.iscsi_target.iqn)"
if [ -n "$IQN" ]; then
    create_iscsi_target
    for DEV in $(getargs rd.iscsi_target.dev=); do
        add_iscsi_device "$DEV"
    done
    info "iscsi-target: Started successfully."
    info "iscsi-target: Ready to receive initiator connections."
    info "iscsi-target: Target devices:"
    for f in "$TARGET/iscsi/$IQN/tpgt_1/lun"/lun_*/*/udev_path; do
        info "iscsi-target:   $f:$(cat "$f")"
    done
    info "iscsi-target: Preventing regular boot and dropping to shell..."
    emergency_shell --shutdown
    exit 1
fi
