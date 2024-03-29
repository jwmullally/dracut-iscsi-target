#!/usr/bin/sh

type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh

TARGET='/sys/kernel/config/target'

create_iscsi_target() {
    if [ -n "$DRACUT_SYSTEMD" ]; then
        systemctl start sys-module-configfs.device
    fi
    modprobe -a target_core_mod target_core_iblock iscsi_target_mod
    mkdir "$TARGET/core/iblock_0"
    mkdir "$TARGET/iscsi"
    mkdir "$TARGET/iscsi/$IQN"
    mkdir "$TARGET/iscsi/$IQN/tpgt_1"
    echo 1 > "$TARGET/iscsi/$IQN/tpgt_1/attrib/authentication"
    mkdir "$TARGET/iscsi/$IQN/tpgt_1/acls/$IN_IQN"
    getarg rd.iscsi.username | tr -d '\n' > "$TARGET/iscsi/$IQN/tpgt_1/acls/$IN_IQN/auth/userid"
    getarg rd.iscsi.password  | tr -d '\n' > "$TARGET/iscsi/$IQN/tpgt_1/acls/$IN_IQN/auth/password"
    getarg rd.iscsi.in.username  | tr -d '\n' > "$TARGET/iscsi/$IQN/tpgt_1/acls/$IN_IQN/auth/userid_mutual"
    getarg rd.iscsi.in.password  | tr -d '\n' > "$TARGET/iscsi/$IQN/tpgt_1/acls/$IN_IQN/auth/password_mutual"
}

enable_iscsi_target() {
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
    mkdir "$TARGET/iscsi/$IQN/tpgt_1/acls/$IN_IQN/lun_$LUN"
    if ! ln -s "$TARGET/iscsi/$IQN/tpgt_1/lun/lun_$LUN" "$TARGET/iscsi/$IQN/tpgt_1/acls/$IN_IQN/lun_$LUN/link_lun_$LUN"; then
        die "iscsi-target: Unable link \"$DEVICE\" to \"$IN_IQN\""
    fi
    echo "0" > "$TARGET/iscsi/$IQN/tpgt_1/acls/$IN_IQN/lun_$LUN/write_protect"
}

IQN="$(getarg rd.iscsi_target.iqn)"
IN_IQN="$(getarg rd.iscsi.initiator)"
if [ -n "$IQN" ] && [ -n "$IN_IQN" ]; then
    # TODO: Handle with built-in dracut functionality
    info "iscsi_target: Waiting for devices to settle"
    sleep 3
    info "iscsi-target: Creating target and adding devices..."
    create_iscsi_target
    info "iscsi-target: Creating target and adding devices..."
    for DEV in $(getargs rd.iscsi_target.dev=); do
        info "iscsi-target:  Adding $DEV"
        add_iscsi_device "$DEV"
    done
    enable_iscsi_target
    info "iscsi-target: Started successfully."
    info "iscsi-target: Ready to receive initiator connections."
    info "iscsi-target: Target devices:"
    for f in "$TARGET/iscsi/$IQN/tpgt_1/acls/$IN_IQN"/lun_*/*/*/udev_path; do
        info "iscsi-target:   $f:$(cat "$f")"
    done
    # TODO: Handle with built-in dracut functionality
    info "iscsi-target: Preventing regular boot and dropping to shell..."
    emergency_shell --shutdown "iscsi-target" "iscsi-target started and ready to receive connections. Halting regular boot and dropping to shell."
    exit 1
fi
