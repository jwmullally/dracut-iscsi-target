# Kickstart file to create minimal Fedora host
# Tested with Fedora 32

text
lang en_US.UTF-8
keyboard us
timezone Etc/UTC
auth --useshadow --passalgo=sha512
selinux --enforcing
firewall --enabled --service=mdns
services --enabled=sshd,NetworkManager,chronyd
network --hostname test-target --bootproto=dhcp --device=link --activate
rootpw --plaintext fedora
shutdown

zerombr
clearpart --all --initlabel --disklabel=gpt
part /boot/efi --fstype=efi --size=200
part /boot --fstype=ext4 --size=512
part / --grow --fstype=ext4 --mkfsoptions="-U 5b6621d0-15ae-4c93-b9d6-f2a197a9ef06"

%packages
@core
kernel
%end

%post
sed -i 's/^#*PermitRootLogin .*$/PermitRootLogin yes/g' /etc/ssh/sshd_config
%end
