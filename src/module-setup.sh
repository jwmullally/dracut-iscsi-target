#!/bin/bash

# called by dracut
check() {
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
    echo "rd.iscsi.username=$dracut_iscsi_target_username"
    echo "rd.iscsi.password=$dracut_iscsi_target_password"
}

# called by dracut
install() {
    inst_multiple grep sort tail
    inst_hook pre-mount 99 "$moddir/iscsi-target.sh"
    cmdline > "${initdir}/etc/cmdline.d/95iscsi-target.conf"
}
