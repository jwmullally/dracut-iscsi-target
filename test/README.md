## Testing

The test creates 2 libvirtd virtual machines connected to the `default`
local network, and thus requires them being created in the `qemu:///system`
libvirt instance.


### Contents

* [mk-vm-test-target.sh](mk-vm-test-target.sh):

    Generates a minimal Fedora VM `test-target` for testing. After
    `install-pkg.sh` below finishes, this can be restarted with the "iSCSI
    Target" boot entry to listen for connections from the `test-initiator`
    host. Hardcoded MAC addresses and partition UUIDs so that we can
    can configure `/etc/dracut.d/iscsi-target.conf` deterministically.

    `sudo` is used to run virt-install.

* [fedora-minimal.ks](fedora-minimal.ks):

    A minimal kickstart file used to create the `test-target` vm.

* [install-pkg.sh](install-pkg.sh):

    Connects to the test host, uploads + installs + configures the 
    iscsi-target RPM and copies the generated `iscsi-boot-*.iso` file to 
    the local host.

    Can be run repeatedly when the `test-target` VM is booted in normal
    non-iSCSI-Target mode.

* [mk-vm-test-initiator.sh](mk-vm-test-initiator.sh):

    Makes a diskless VM `test-initiator` to boot with `iscsi-boot-*.iso`.
    This will boot as a regular Dracut iSCSI initiator connecting to
    the iSCSI target running on the `test-target` VM.

    `sudo` is used to run virt-install.


### Example workflow

```
./mk-vm-test-target.sh
./install-pkg.sh
# Boot test-target into "iSCSI Target" mode
./mk-vm-test-initiator.sh

# Repeat:
#   Make changes to the package
#   Boot test-target into normal mode
./install-pkg.sh
#   Boot test-target into "iSCSI Target" mode
#   Boot test-initiator
```
