#!/bin/bash
set -x

echo "Beginning of teardown!"

systemctl stop libvirt-nosleep@"$OBJECT"  2>&1 | tee -a /var/log/libvirt/custom_hooks.log

for file in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
  echo "powersave" > $file;
done

modprobe amdgpu

systemctl start display-manager

# Rebind VT consoles (adapted from https://www.kernel.org/doc/Documentation/fb/fbcon.txt)
input="/tmp/vfio-bound-consoles"
while read consoleNumber; do
  if test -x /sys/class/vtconsole/vtcon${consoleNumber}; then
      if [ `cat /sys/class/vtconsole/vtcon${consoleNumber}/name | grep -c "frame buffer"` \
           = 1 ]; then
    echo "Rebinding console ${consoleNumber}"
	  echo 1 > /sys/class/vtconsole/vtcon${consoleNumber}/bind
      fi
  fi
done < "$input"


echo "End of teardown!"
