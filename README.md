# dracut-iscsi-target

*!! Currently there is NO AUTHENTICATION and NO ENCRYPTION for the iSCSI
endpoint. See TODO below. For now, only run this on a trusted network
with trusted hosts.*

This package adds an extra module to dracut that allows the initramfs to
start as an iSCSI Target instead of doing a regular boot.

This allows you to run the OS on another host using "netroot=iscsi:...".

For example, you can run your laptop's OS on your desktop without having
to install and maintain a seperate copy.


## Usage

- Install the package

- Edit `/etc/dracut.conf.d/iscsi-target.conf`

- Run these commands to regenerate the initramfs image for the running
  kernel and to add the extra "iSCSI Target" boot entry. This should
  only be needed once, as these are automatically run every time a new
  kernel version is installed. (In case this fails, make sure you have
  at least one older kernel available as a fallback or make a backup 
  bootdisk).

    ```
    /bin/kernel-install remove $(uname -r)
    /bin/kernel-install add $(uname -r) /lib/modules/$(uname -r)/vmlinuz
    ```

- Run `mk-dracut-iscsi-target-iso.sh` to generate `iscsi-boot.iso`.
  This contains a copy of the kernel and initramfs with the necessary
  initrd cmdline arguments to do an iSCSI boot to the target. You will
  need to run this every time you install a new kernel (see TODO).

- Burn the ISO to a CD, or copy to a USB key like so:

    ```
    dd if=iscsi-boot.iso of=/dev/disk/by-id/usb-Kingston_DataTraveler_II+_ABCDE01234-0\:0
    ```

- Reboot the host and select the "iSCSI Target" entry. After the target
  is configured, this will stop the regular boot sequence and drop to an
  emergency shell. Use `journalctl` and check for lines beginning with
  "iscsi-target:" to ensure everything is setup correctly.

- Boot the client/initiator host using the CD or USB key.

- After configuring the network and iSCSI target, the client should
  now begin booting into the target's OS.

By default, the IP configuration for the target and initiator is a
private point-to-point link. If the network interface you are using for
the iSCSI connection is also the one you want to use as a regular
network connection, you can create an alias interface like so:

    $ cat > /etc/sysconfig/network-scripts/ifcfg-bootnet0:0 << EOF
    NM_CONTROLLED="no"
    DEVICE="bootnet0:0"
    ONBOOT=yes
    BOOTPROTO=dhcp
    EOF
    $ ifup bootnet0:0


## Troubleshooting

Due to network startup delays, the iSCSI initiator might need two
connection attempts to succeed.

You will need the kernel module for the NIC of the client/initiator
host to be in the initramfs image. Either modify the "add_drivers"
line, or set "hostonly=no" to include the module.

If the dracut boot sequence fails, you can debug it by appending
"rd.shell" to the cmdline to drop to a shell on error, or use
"rd.break=..." to set a breakpoint. See `dracut.cmdline(7)` for more
information.


## TODO

- iSCSI CHAP authentication
- - scrub iSCSI creds from /proc/cmdline after boot?
- - Stop new connections after first to prevent rogue user code from 
    accessing the disk?
- - Bake creds into image or prompt? 
- [MACSEC L2 encryption](https://developers.redhat.com/blog/2016/10/14/macsec-a-different-solution-to-encrypt-network-traffic/)
- Support a custom kernel post-install script for automatically 
  generating the ISO and writing it to a custom location (e.g. USB key)
- Safer first-install initramfs generation instructions


## Contributions

Patches are welcome.

- Test with the sample VMs in [test](./test) before opening a pull 
  request.
- Stick to basic POSIX shell where possible. Minimize shellcheck errors.


## Author

Copyright (C) 2018 Joseph Mullally

License: [MIT](./LICENCE.txt)

Project: https://github.com/jwmullally/dracut-iscsi-target
