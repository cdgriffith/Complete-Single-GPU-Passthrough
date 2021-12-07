#!/bin/bash

VM_NAME=win10

if [ `whoami` != root ]; then
    echo Please run this script as root or using sudo
    exit 1
fi

# Create hooks directory and copy qemu script
if test -e /etc/libvirt/ && ! test -e /etc/libvirt/hooks;
then
   mkdir -p /etc/libvirt/hooks;
fi
if test -e /etc/libvirt/hooks/qemu;
then
    mv /etc/libvirt/hooks/qemu /etc/libvirt/hooks/qemu_last_backup
fi
cp hooks/qemu /etc/libvirt/hooks/qemu
chmod +x /etc/libvirt/hooks/qemu

# Copy start and stop scripts
mkdir -p /etc/libvirt/hooks/qemu.d/${VM_NAME}/prepare/begin
if test -e /etc/libvirt/hooks/qemu.d/${VM_NAME}/prepare/begin/start.sh;
then
    mv /etc/libvirt/hooks/qemu.d/${VM_NAME}/prepare/begin/start.sh /etc/libvirt/hooks/qemu.d/${VM_NAME}/prepare/begin/start.sh.bk
fi
cp hooks/start.sh /etc/libvirt/hooks/qemu.d/${VM_NAME}/prepare/begin/start.sh
chmod +x /etc/libvirt/hooks/qemu.d/${VM_NAME}/prepare/begin/start.sh

mkdir -p /etc/libvirt/hooks/qemu.d/${VM_NAME}/release/end
if test -e /etc/libvirt/hooks/qemu.d/${VM_NAME}/release/end/stop.sh;
then
    mv /etc/libvirt/hooks/qemu.d/${VM_NAME}/release/end/stop.sh /etc/libvirt/hooks/qemu.d/${VM_NAME}/release/end/stop.sh.bk
fi
cp hooks/start.sh /etc/libvirt/hooks/qemu.d/${VM_NAME}/release/end/stop.sh
chmod +x /etc/libvirt/hooks/qemu.d/${VM_NAME}/release/end/stop.sh

# Copy systemd scripts
if test -e /etc/systemd/system/libvirt-nosleep@.service;
then
    rm /etc/systemd/system/libvirt-nosleep@.service
fi
cp systemd-no-sleep/libvirt-nosleep@.service /etc/systemd/system/libvirt-nosleep@.service

