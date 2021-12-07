#!/usr/bin/env python3
from pathlib import Path
import os
from subprocess import run, PIPE
import xml.etree.ElementTree as ElementTree

vm_name = "win10"

vm_xml_file = f"/etc/libvirt/qemu/{vm_name}.xml"
qemu_script = Path("/etc/libvirt/hooks/qemu")
start_script = Path(f"/etc/libvirt/hooks/qemu.d/{vm_name}/prepare/begin/start.sh")
stop_script = Path(f"/etc/libvirt/hooks/qemu.d/{vm_name}/release/end/stop.sh")


def exec(cmd):
    return run(cmd, shell=True, stdout=PIPE, stderr=PIPE, encoding="utf-8")


iommu_output = exec("journalctl -o short-precise -b 0")
iommu_enabled = "IOMMU enabled" in iommu_output.stdout

libvirtd_status = exec("systemctl status libvirtd")

vga_device = exec("lspci | grep VGA").stdout.split(" ", 1)[0]

region_0 = exec(f'lspci -s {vga_device} -vvv | grep "Region 0"').stdout.strip().rsplit(" ", 1)[1]
bar_disabled = True if "256M" in region_0 else False

tree = ElementTree.parse(vm_xml_file)
root = tree.getroot()

cpu_mode = dict(root.find("cpu").items()).get('mode', '')
xml_machine = dict(root.find("os").find("type").items()).get('machine', '')
xml_loader = root.find("os").find("loader").text
try:
    disk = next(x for x in root.find("devices").findall("disk") if dict(x.items()).get("device") == 'disk')
    disk_cache_type = dict(disk.find("driver").items()).get("cache")
    disk_bus_type = dict(disk.find("target").items()).get("bus")
except Exception:
    disk_cache_type = None
    disk_bus_type = None

try:
    interface = next(x for x in root.find("devices").findall("interface") if dict(x.items()).get("type") == 'network')
    network_type = dict(interface.find("model").items()).get("type")
except Exception:
    network_type = None

def msg(var):
    return "[\033[91mFAIL\033[00m]" if not var else "[\033[92mOK\033[00m]"

def text(var):
    return f"{var} {' ' * (50 - len(var))}"

print(f"""{text('IOMMU enabled')} {msg(iommu_enabled)}
{text('libvirtd service started')} {msg(libvirtd_status.returncode == 0 and "active (running)" in libvirtd_status.stdout)}
{text('Resizable Bar disabled')} {msg(bar_disabled)}
{text('QEMU hook script exists')} {msg(qemu_script.exists() and qemu_script.is_file())}
{text('QEMU hook script executable')} {msg(os.access(qemu_script, os.X_OK))}
{text(f'{vm_name} Start script exists')} {msg(start_script.exists() and start_script.is_file())}
{text(f'{vm_name} Start script executable')} {msg(os.access(start_script, os.X_OK))}
{text(f'{vm_name} Stop script exists')} {msg(stop_script.exists() and stop_script.is_file())}
{text(f'{vm_name} Stop script executable')} {msg(os.access(stop_script, os.X_OK))}
{text(f'{vm_name} XML exists')} {msg(Path(vm_xml_file).exists())}
{text(f'{vm_name} XML firmware is set to UEFI')} {msg("OVMF_CODE" in xml_loader)}
{text(f'{vm_name} XML machine is q35')} {msg("q35" in xml_machine)}
{text(f'{vm_name} XML CPU passthrough enabled')} {msg(cpu_mode == "host-passthrough")}
{text(f'{vm_name} XML Disk cache is writeback')} {msg(disk_cache_type == "writeback")}
{text(f'{vm_name} XML Disk bus is VirtIO')} {msg(disk_bus_type == "virtio")}
{text(f'{vm_name} XML Network is VirtIO')} {msg(network_type in ("virtio", "virtio-net-pci"))}
""")