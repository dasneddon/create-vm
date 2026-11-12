# KVM Virtual Machine Setup

An interactive Bash script for creating virtual machines with **KVM/QEMU**, **libvirt**, and `virt-install` on a Linux host.

The script collects VM settings, validates the inputs, shows a configuration summary for confirmation, and creates the virtual machine.

## Requirements

- A Linux host with KVM virtualization support
- QEMU and libvirt installed and running
- `virt-install` and `virsh`
- OVMF firmware installed if using UEFI
- Permission to run `sudo virsh` and `sudo virt-install`
- An installation ISO accessible to the host

On Ubuntu, the relevant packages can be installed with:

```bash
sudo apt update
sudo apt install qemu-kvm libvirt-daemon-system libvirt-clients virtinst ovmf
```

The script uses libvirt's **`default` NAT network**. Verify that it exists and is active:

```bash
sudo virsh net-list --all
sudo virsh net-start default      # Only if inactive
sudo virsh net-autostart default
```

## Usage

Make the script executable and run it (replace `create-vm.sh` with the actual script filename):

```bash
chmod +x create-vm.sh
./create-vm.sh
```

Follow the prompts and type `yes` at the summary to create the VM, `quit` to exit, or anything else to restart configuration.

## Configuration

| Setting | Default | Accepted input |
| --- | --- | --- |
| VM name | Current date and time | VM name |
| RAM | 4096 MB | 1–8192 MB |
| CPUs | Script-defined prompt default | 1–6 |
| Virtual disk | 30 GB | 1–100 GB |
| Firmware | UEFI | UEFI or BIOS |
| Installation ISO | None | Filename or absolute path |
| Guest OS | auto | OS identifier supported by `virt-install` |
| Network | `default` | libvirt NAT network (fixed in script) |

For the ISO prompt, an **absolute path** is used as entered. A **filename or relative path** is resolved under `/var/lib/libvirt/boot/`.

Example:

```text
ISO filename/path: ubuntu-24.04.3-live-server-amd64.iso
```

This resolves to `/var/lib/libvirt/boot/ubuntu-24.04.3-live-server-amd64.iso`.

## Virtual Machine Settings

The script configures each VM with:

- A **QCOW2** virtual disk using the **VirtIO** bus
- **VirtIO** networking on libvirt's `default` NAT network
- **UEFI or BIOS** firmware, as selected
- A **VNC console** bound to `127.0.0.1` on the host
- **Host CPU passthrough** (`host-passthrough`)
- Installation media attached via `--cdrom`
- No automatic local console attachment (`--noautoconsole`)

The script checks for an existing VM with the same name before creating one.

## Accessing the VNC Console

Find the assigned VNC display:

```bash
sudo virsh vncdisplay VM_NAME
```

For example, display `:0` normally corresponds to TCP port `5900`; display `:1` to port `5901`.

Because VNC listens only on the host's loopback interface, connect locally or forward the port over SSH. For display `:0`:

```bash
ssh -L 5900:127.0.0.1:5900 USER@HOST
```

Then point a VNC viewer at `127.0.0.1:5900` on your own computer. The posted script configures a VNC password; keep that credential private.

## Managing VMs

```bash
# List all virtual machines
sudo virsh list --all

# Show VM information
sudo virsh dominfo VM_NAME

# Start a VM
sudo virsh start VM_NAME

# Graceful shutdown (requires guest support)
sudo virsh shutdown VM_NAME

# Force power off if necessary
sudo virsh destroy VM_NAME

# Enable startup when the host boots
sudo virsh autostart VM_NAME

# Disable automatic startup
sudo virsh autostart --disable VM_NAME
```

## Notes

- VM installation requires access to the selected ISO by libvirt/QEMU.
- Disk and memory limits are defined by the script, not necessarily by the hypervisor.
- The selected guest OS identifier must be recognized by the installed `virt-install`/libosinfo version; `auto` enables detection without requiring a match.
- The script creates the VM but does not install or configure the guest operating system automatically.
