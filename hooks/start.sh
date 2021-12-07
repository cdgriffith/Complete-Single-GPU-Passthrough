#!/bin/bash
set -x

echo "Beginning of startup!"

systemctl start libvirt-nosleep@"$OBJECT"  2>&1 | tee -a /var/log/libvirt/custom_hooks.log

for file in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
  echo "performance" > $file;
done

systemctl stop display-manager

# Unbind VTconsoles if currently bound (adapted from https://www.kernel.org/doc/Documentation/fb/fbcon.txt)
if test -e "/tmp/vfio-bound-consoles" ; then
    rm -f /tmp/vfio-bound-consoles
fi
for (( i = 0; i < 16; i++))
do
  if test -x /sys/class/vtconsole/vtcon${i}; then
      if [ `cat /sys/class/vtconsole/vtcon${i}/name | grep -c "frame buffer"` = 1 ]; then
	       echo 0 > /sys/class/vtconsole/vtcon${i}/bind
           echo "Unbinding console ${i}"
           echo $i >> /tmp/vfio-bound-consoles
      fi
  fi
done

modprobe -r amdgpu

###### This is a failsafe ######
# Load VFIO-PCI driver
modprobe vfio-pci

echo "End of startup!"
