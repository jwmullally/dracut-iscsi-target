# dracut-iscsi-target

*!! Alpha software - may break your computer.*

*!! Currently there is NO ENCRYPTION for the iSCSI endpoint. See TODO
below. For now, only run this on a trusted network with trusted hosts.*

This dracut module allows the initramfs to start as an iSCSI Target
instead of doing a regular boot.

This allows you to run the OS on another host using `netroot=iscsi:...`.
For example, you can run your laptop OS on your desktop without having
to install and maintain a seperate copy.


## Usage

- Install the package

- Edit `/etc/dracut.conf.d/iscsi-target.conf`

- Run these commands to regenerate the initramfs image for the running
  kernel and to add the extra `iSCSI Target` boot entry. This should
  only be needed once, as these are automatically run every time a new
  kernel version is installed. (In case this fails, make sure you have
  at least one older kernel available as a fallback or make a backup 
  bootdisk).

    ```
    kernel-install add $(uname -r) /lib/modules/$(uname -r)/vmlinuz
    ```

- Run this command to generate `iscsi-boot.iso`. This contains a
  copy of the kernel and initramfs, along with the necessary initrd
  cmdline arguments to do an iSCSI boot to the target. You will need to
  run this every time you install a new kernel (see TODO).

    ```
    mk-dracut-iscsi-target-iso.sh
    ```

- Burn the ISO to a CD, or copy to a USB key like so:

    ```
    dd if=iscsi-boot.iso of=/dev/disk/by-id/usb-Kingston_DataTraveler_II+_ABCDE01234-0\:0
    ```

- Reboot the host and select the `iSCSI Target` entry. After the target
  is configured, this will stop the regular boot sequence and drop to an
  emergency shell. Use `journalctl` and check for lines beginning with
  `iscsi-target:` to ensure everything is setup correctly.

- Boot the client/initiator host using the CD or USB key.

- After configuring the network and iSCSI target, the client should
  now begin booting into the target's OS.


## Issues


### Networking

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


### Reinstalling kernels

Doing a `dnf reinstall kernel-core` can result in the kernel arguments
for your regular kernel GRUB entries becoming corrupted.

`new-kernel-pkg` (called from `kernel-install`/kernel RPM scripts) uses
`grubby --copy-default` to copy the kernel arguments for new entries
from the default entry marked in GRUB.

During `dnf reinstall kernel-core`, when the default kernel is removed
`grubby` will copy from whatever is there, including the `iscsi-target`
entry. This can result in extra kernel arguments being included in all
the default kernels, preventing regular boot.

A workaround is to edit `/etc/grub2.cfg` manually and remove the extra
args.

(Newer scripts for managing Boot Loader Spec `/boot/loader/entries`
instead use files like `/etc/kernel/cmdline` to avoid this issue).


## Troubleshooting

Due to network startup delays, the iSCSI initiator might need two
connection attempts to succeed.

You will need the kernel module for the NIC of the client/initiator
host to be in the initramfs image. Either modify the `add_drivers`
line, or set `hostonly=no` to include all modules. See `dracut.conf(5)`
for more information.

If the dracut boot sequence fails, you can debug it by appending
`rd.shell` to the cmdline to drop to a shell on error, or use
`rd.break=...` to set a breakpoint. See `dracut.cmdline(7)` for more
information.


## TODO

- Improve iSCSI CHAP authentication
- - Mutual auth
- - initiator specific ACL
- [MACSEC L2 encryption](https://developers.redhat.com/blog/2016/10/14/macsec-a-different-solution-to-encrypt-network-traffic/)
- Support a custom kernel post-install script for automatically 
  generating the ISO and writing it to a custom location (e.g. USB key)
- systemd-boot EFI entry (?)


## Developing

Patches are welcome.

- Test with the sample VMs in [test](./test) before opening a pull 
  request.
- Stick to basic POSIX shell where possible. Minimize shellcheck errors.


### LIO Target ConfigFS

As most LIO Target documentation uses `targetcli`, you can use `strace`
to see what it writes to the ConfigFS at `/sys/kernel/config/target/`:

    targetcli clearconfig confirm=True
    tcli() { strace -e trace=symlink,mkdir,open,openat,write -s 4096 targetcli $1 2>&1 | grep -A9999 run_cmdline ; }
    tcli 'backstores/block create root0 /dev/vdb'
    tcli 'iscsi/ create iqn.2009-02.com.example:for.all'
    tcli 'iscsi/iqn.2009-02.com.example:for.all/tpg1 set attribute authentication=0 demo_mode_write_protect=0 generate_node_acls=1'
    tcli 'iscsi/iqn.2009-02.com.example:for.all/tpg1/luns create /backstores/block/root0 1'


## Reference

- [LIO - The Linux SCSI Target Wiki](http://linux-iscsi.org/wiki/ISCSI)
- [dracut.conf(5)](http://man7.org/linux/man-pages/man5/dracut.conf.5.html)
- [dracut.cmdline(7)](http://man7.org/linux/man-pages/man7/dracut.cmdline.7.html)
- [systemd-boot](https://www.freedesktop.org/wiki/Software/systemd/systemd-boot/)


## Author

Copyright (C) 2018 Joseph Mullally

License: [MIT](./LICENCE.txt)

Project: https://github.com/jwmullally/dracut-iscsi-target
