#!/bin/sh
set -ex

virt-install \
    --connect qemu:///system \
    --name test-target \
    --ram 2048 \
    --vcpus 2 \
    --arch x86_64 \
    --os-variant fedora34 \
    --boot uefi \
    --disk size=4,serial=abcd1234 \
    --disk size=1,serial=eabc5678 \
    --disk size=1,serial=MOCKUSB1 \
    --network default,mac=52:54:00:46:41:46 \
    --location  http://dl.fedoraproject.org/pub/fedora/linux/releases/34/Everything/x86_64/os/ \
    --initrd-inject=fedora-minimal.ks \
    --extra-args "inst.ks=file:/fedora-minimal.ks"
