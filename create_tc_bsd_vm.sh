#!/usr/bin/env bash
#
#  by @klauer, loosely based on https://github.com/PTKu/TwinCAT-BSD-VM-creator

set -e

usage () {
  echo "Usage: $0 vm_name [tcbsd_iso_image]" >&2
  exit 0
}

die () {
  echo "$@" >&2
  exit 1
}

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
VM_NAME=$1
TCBSD_ISO_IMAGE=$2
VM_HDD="$PWD/$VM_NAME/$1.vhd"

if [[ $# -lt 1 || $# -gt 2 || -z "$VM_NAME" ]]; then
  usage
fi

if [ -z "$TCBSD_ISO_IMAGE" ]; then
  # shellcheck disable=SC2012
  TCBSD_ISO_IMAGE=$(ls "${SCRIPT_DIR}/TCBSD"*.iso | head -n 1)
fi

echo "* VM name: ${VM_NAME}"
echo "* TcBSD ISO: ${TCBSD_ISO_IMAGE}"
echo "* Disk name: ${VM_NAME}"

if [ ! -f "$TCBSD_ISO_IMAGE" ]; then
  die "
* TcBsd ISO image not found. Download it here:
  -> https://www.beckhoff.com/en-en/products/ipc/software-and-tools/operating-systems/c9900-s60x-cxxxxx-0185.html
"
fi

if ! command -v VBoxManage &>/dev/null; then
  die "VirtualBox installation not found."
fi

TCBSD_VDI_IMAGE="$SCRIPT_DIR/$(basename "${TCBSD_ISO_IMAGE%.*}").vdi"

echo "* TcBSD VirtualBox-specific VDI: ${TCBSD_VDI_IMAGE}"

vbox_manage() {
  echo "Running: VBoxManage $*"
  VBoxManage "$@"
  EXIT_CODE=$?
  if [ $EXIT_CODE -gt 0 ]; then
    echo "VBoxManage reported exit code $EXIT_CODE; exiting early."
    exit "$EXIT_CODE"
  fi
  echo ""
}

show_vm_info() {
  VBoxManage showvminfo "$1"
}

set +e

if [ ! -f "$TCBSD_VDI_IMAGE" ]; then
  echo "* Converting ISO to TcBSD VirtualBox-specific VDI"
  vbox_manage convertfromraw --format VDI "$TCBSD_ISO_IMAGE" "$TCBSD_VDI_IMAGE" 2>&1
fi

if show_vm_info "$VM_NAME" &> /dev/null; then
  echo "VBoxManage reports that the VM ${VM_NAME} already exists."
  read -rp "Delete it? [yN]" yn

  if [[ "$yn" != "y" ]]; then
    echo "VM already exists; cannot continue" >/dev/stderr
    exit 1
  fi

  echo "Unregistering ${VM_NAME} from VirtualBox and moving files to a backup directory."
  set -x
  vbox_manage unregistervm "$VM_NAME"
  mv "$VM_NAME" "${VM_NAME}.old.$(date +%s)"
  set +x
fi

echo "* Creating the VM"
vbox_manage createvm --name "$VM_NAME" --basefolder "$PWD" --ostype FreeBSD_64 --register

echo "* Setting VM basic settings"
vbox_manage modifyvm "$VM_NAME" --memory 1024 --vram 128 --acpi on --hpet on --graphicscontroller vmsvga --firmware efi64

echo "* Setting VM storage settings"
vbox_manage storagectl "$VM_NAME" --name SATA --add sata --controller IntelAhci --hostiocache on --bootable on

echo "* Attaching to installation HDD to SATA Port 1"
vbox_manage storageattach "$VM_NAME" --storagectl "SATA" --device 0 --port 1 --type hdd --medium "$TCBSD_VDI_IMAGE"

echo "* Creating an empty 8GB disk image for the TwinCAT BSD installation"
vbox_manage createmedium --filename "$VM_HDD" --size 8192 --format VHD 2>&1

echo "* Attaching the empty disk image to SATA Port 0"
vbox_manage storageattach "$VM_NAME" --storagectl "SATA" --device 0 --port 0 --type hdd --medium "$VM_HDD"

if command -v xdg-open &>/dev/null; then
  OPEN="xdg-open"
elif command -v open &>/dev/null; then
  OPEN="open"
elif command -v start.exe &>/dev/null; then
  OPEN="start.exe"
else
  echo "Created VM but unable to figure out how to show it to you.  Look in $PWD/$VM_NAME"
  ls "$PWD/$VM_NAME"
  exit 0
fi

"$OPEN" "$PWD/$VM_NAME"
