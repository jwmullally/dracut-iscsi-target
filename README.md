# dracut-iscsi-target

*!! Beta software - may prevent your computer from booting.*

*!! Currently there is NO ENCRYPTION for the iSCSI endpoint. See TODO
below. For now, only run this on a trusted network with trusted hosts.*

This dracut module allows the Fedora initramfs to start as an iSCSI Target
instead of doing a regular boot.

This allows you to run the OS on another host using `netroot=iscsi:...`.
For example, you can run your laptop OS on your desktop without having
to install and maintain a seperate copy.

## Packages

- RPM: <a href="https://copr.fedorainfracloud.org/coprs/jwmullally/dracut-iscsi-target/package/dracut-iscsi-target/">Fedora COPR<img src="https://copr.fedorainfracloud.org/coprs/jwmullally/dracut-iscsi-target/package/dracut-iscsi-target/status_image/last_build.png" /></a>

    ```
    dnf copr enable jwmullally/dracut-iscsi-target
    dnf install dracut-iscsi-target
    ```


## Usage

- Install the package.

- Edit `/etc/dracut.conf.d/iscsi-target.conf`. The items you will want
  to modify first are:

  - `rd.iscsi_target.dev=<your target block devices>`
  - `ifname=bootnet0:<your NIC MAC addresses>`
  - `root=<your root block devices UUID>`
  
- Run this command to regenerate the initramfs image for the running
  kernel and to add the extra `iSCSI Target` boot entry. This should
  only be needed once, as this is automatically run every time a new
  kernel version is installed. (In case this fails, make sure you have
  at least one older kernel available as a fallback or make a backup 
  bootdisk).

    ```
    kernel-install --verbose add $(uname -r) /lib/modules/$(uname -r)/vmlinuz
    ```

  This also creates `/boot/iscsi-boot-$(uname -r).iso`. The ISO contains
  a copy of the kernel and initramfs, along with the necessary initrd
  cmdline arguments to do an iSCSI boot to the target.

- Burn the ISO to a CD, or copy to a USB key like so:

    ```
    dd if=/boot/iscsi-boot-$(uname -r).iso of=/dev/disk/by-id/usb-Kingston_DataTraveler_II+_ABCDE01234-0\:0
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
network connection, you can add DHCP to this interface with the following:

    rm -f /etc/sysconfig/network-scripts/ifcfg-bootnet0
    nmcli con reload
    nmcli con mod bootnet0 ipv4.method auto
    nmcli con up bootnet0


## Troubleshooting

Due to network startup delays, the iSCSI initiator might need two
connection attempts to succeed.

You will need the kernel module for the NIC of the client/initiator
host to be in the initramfs image. Either modify the `add_drivers`
line, or set `hostonly=no` to include all modules. See `dracut.conf(5)`
for more information.

If the dracut boot sequence fails, you can debug it by appending
`rd.shell` to the cmdline to drop to a shell on error, or use
`rd.debug` to enable verbose shell command tracing, or
`rd.break=...` to set a breakpoint. Remove `rhgb` and `quiet`
to see kernel and system messages. See `dracut.cmdline(7)` for 
more information.


## TODO

- [MACSEC L2 encryption](https://developers.redhat.com/blog/2016/10/14/macsec-a-different-solution-to-encrypt-network-traffic/)
- Support a custom kernel post-install script for automatically 
  generating the ISO and writing it to a custom location (e.g. USB key)
- Make initiator add devices in LUN order
  - (wireshark suggests they are being added in order reported by target)
- Remove need for specifying `$dracut_iscsi_target_boot_prefix`
- Sort "iSCSI Target" entry under Fedora entries in bootloader menu
- Add UEFI boot to the generated ISO


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
    tcli 'iscsi/iqn.2009-02.com.example:for.all/tpg1/acls create iqn.2009-02.com.initiator:for.all'


## Reference

- [LIO - The Linux SCSI Target Wiki](http://linux-iscsi.org/wiki/ISCSI)
- [dracut.conf(5)](http://man7.org/linux/man-pages/man5/dracut.conf.5.html)
- [dracut.cmdline(7)](http://man7.org/linux/man-pages/man7/dracut.cmdline.7.html)
- [dracut modules](https://github.com/dracutdevs/dracut/blob/master/README.modules)
- [systemd-boot](https://www.freedesktop.org/wiki/Software/systemd/systemd-boot/)


## Author

Copyright (C) 2018 Joseph Mullally

License: [MIT](./LICENCE.txt)

Project: <https://github.com/jwmullally/dracut-iscsi-target>
