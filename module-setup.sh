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

# called by dracut
install() {
    inst_multiple grep sort tail
    inst_hook pre-mount 99 "$moddir/iscsi-target.sh"
}
