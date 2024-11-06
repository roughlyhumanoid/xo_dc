#!/bin/bash
sudo virt-install --name udub \
--os-variant ubuntu22.04 \
--vcpus 2 \
--memory 4096 \
--location /var/lib/libvirt/images/ubuntu-22.04.4-live-server-amd64.iso,kernel=casper/vmlinuz,initrd=casper/initrd \
--network bridge=virbr0,model=virtio \
--disk size=30 \
--graphics none \
--extra-args='console=ttyS0,115200n8 --- console=ttyS0,115200n8' \
--debug
