#!/bin/bash

# called by dracut
check() {
    require_binaries grep sort tail || return 1
    return 255
}

# called by dracut
depends() {
    echo network
    return 0
}

# called by dracut
installkernel() {
    hostonly='' instmods "=drivers/target"
}

cmdline() {
    echo -n " rd.iscsi.username=$dracut_iscsi_target_username"
    echo -n " rd.iscsi.password=$dracut_iscsi_target_password"
    echo -n " rd.iscsi.in.username=$dracut_iscsi_target_in_username"
    echo -n " rd.iscsi.in.password=$dracut_iscsi_target_in_password"
}

# called by dracut
install() {
    inst_multiple grep sort tail
    inst_hook pre-mount 99 "$moddir/iscsi-target.sh"
    # Use the initiatorname set by "rd.iscsi.initiator"
    rm -f "${initdir}/etc/iscsi/initiatorname.iscsi"
    cmdline > "${initdir}/etc/cmdline.d/95iscsi-target.conf"
}
