#!/usr/bin/env bash
clear
DEFAULT_NAME="$(date +%Y-%m-%d)_at_$(date +%H:%M:%S)"
VM_NETWORK="default"
while true; do
    read -r -p "VM name [VM-$DEFAULT_NAME]: " VM_NOM
    VM_NOM="${VM_NOM:-$DEFAULT_NAME}"
    VM_NAME="VM-$VM_NOM"
    while true; do
        read -r -p "RAM (MB) [4096]: " VM_RAM
        VM_RAM="${VM_RAM:-4096}"
        if [[ "$VM_RAM" =~ ^[0-9]+$ ]] && (( 10#$VM_RAM >= 1 && 10#$VM_RAM <=8192 )); then
            break
        fi

        echo "Error: RAM must be between 1 and 8192 MB."
    done
    while true; do
        read -r -p "CPUs [2]: " VM_CPUS
        VM_CPUS="${VM_CPUS:-2}"
        if [[ "$VM_CPUS" =~ ^[1-6]$ ]]; then
            break
        fi

        echo "Error: CPU count must be between 1 and 6."
    done
    while true; do
        read -r -p "Disk size (GB) [30]: " VM_DISK
        VM_DISK="${VM_DISK:-30}"
        if [[ "$VM_DISK" =~ ^[0-9]+$ ]] && (( 10#$VM_DISK >=1 && 10#$VM_DISK <= 100)); then
            break
        fi

        echo "Error: Disk size must be between 1 and 100 GB."
    done
    while true; do
        read -r -p "Firmware (UEFI/BIOS) [UEFI]: " VM_FIRMWARE
        VM_FIRMWARE="${VM_FIRMWARE:-UEFI}"
        if [[ "${VM_FIRMWARE^^}" == "UEFI" ]]; then
            VM_BOOT="uefi,firmware.feature0.name=secure-boot,firmware.feature0.enabled=no"
            break
        elif [[ "${VM_FIRMWARE^^}" == "BIOS" ]]; then
            VM_BOOT="firmware=bios"
            break
        fi

        echo "Error: Enter UEFI or BIOS."
    done

    while true; do
        read -r -p "ISO filename or path (quit to exit), default folder is /var/lib/libvirt/boot/: " VM_ISO_INPUT

        if [[ "${VM_ISO_INPUT^^}" == "QUIT" ]]; then
            echo "Exiting VM setup."
            exit 0
        fi

        if [[ "$VM_ISO_INPUT" == /* ]]; then
            VM_ISO="$VM_ISO_INPUT"
        else
            VM_ISO="/var/lib/libvirt/boot/$VM_ISO_INPUT"
        fi

        if [[ -f "$VM_ISO" ]]; then
            break
        fi

        echo "Error: ISO file not found: $VM_ISO"
    done
    read -r -p "Guest OS [auto]: " VM_OS
    VM_OS="${VM_OS:-auto}"

    if [[ "${VM_OS,,}" == "auto" ]]; then
            VM_OSINFO="detect=on,require=off"
    else
            VM_OSINFO="name=$VM_OS"
    fi

    echo 
    echo "Virtual Machine Setup"
    echo "---------------------"
    echo "Starting VM configuration..."
    echo "Name: $VM_NAME"
    echo "RAM: $VM_RAM MB"
    echo "CPUs: $VM_CPUS"
    echo "Disk: $VM_DISK GB"
    echo "Network: $VM_NETWORK (NAT)"
    echo "Firmware: $VM_FIRMWARE"
    echo "ISO: $VM_ISO"
    echo "Guest OS: $VM_OS"
    echo "---------------------"
    read -r -p "Accept? Type 'yes' to confirm or 'quit' to quit: " CONFIRM
        if [[ "${CONFIRM^^}" == "YES" ]]; then
            echo "Creating $VM_NAME"
            break
        elif [[ "${CONFIRM^^}" == "QUIT" ]]; then
            echo "Exiting VM setup."
            exit 0
        else
            echo "Starting over..."
        fi
        
    echo "Starting VM configuration..."
    echo "---------------------"
done

VM_ARGS=(
    --name "$VM_NAME"
    --memory "$VM_RAM"
    --vcpus "$VM_CPUS"
    --network "network=$VM_NETWORK,model=virtio"
    --disk "size=$VM_DISK,format=qcow2,bus=virtio"
    --boot "$VM_BOOT"
    --osinfo "$VM_OSINFO"
    --graphics vnc,listen=127.0.0.1,passwd=dsneddon
    --noautoconsole
    --cdrom "$VM_ISO"
    --cpu host-passthrough

)

if sudo virsh -c qemu:///system dominfo "$VM_NAME" &>/dev/null; then
    echo "Error: VM '$VM_NAME' already exists." >&2
    exit 2
fi

if sudo virt-install "${VM_ARGS[@]}"; then
    echo "Successfully created $VM_NAME"
else
    echo "Error: VM creation failed." >&2
    exit 1
fi


