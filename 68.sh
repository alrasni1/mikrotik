#!/bin/bash -e

echo
echo "=== ABDULLAH ALRASNI - MikroTik CHR Installer (with DHCP) ==="
echo

sleep 3

# Download CHR image (version 6.48.6)
echo "[+] Downloading MikroTik CHR 6.48.6..."
wget https://download.mikrotik.com/routeros/6.48.6/chr-6.48.6.img.zip -O chr.img.zip

# Extract the image from the ZIP file
echo "[+] Extracting image..."
unzip -p chr.img.zip > chr.img

# Mount the image to modify its contents (offset 512 skips MBR)
mkdir -p /mnt/chr
mount -o loop,offset=512 chr.img /mnt/chr

# Create the automatic configuration script for CHR
cat <<EOF > /mnt/chr/run.auto.rsc
/interface ethernet reset-mac-address numbers=0
/ip dhcp-client add interface=ether1 disabled=no
/ip service disable telnet
/user set 0 name=root password=root
EOF

# Unmount the image after modification
umount /mnt/chr

# List available disks and ask the user to choose one (danger: data loss)
echo
lsblk
echo
read -p "!!! WARNING: This will ERASE a disk completely. Enter target disk (e.g., sda): " STORAGE

# Validate the disk input
if [[ ! -b /dev/$STORAGE ]]; then
  echo "[ERROR] Invalid disk: /dev/$STORAGE"
  exit 1
fi

# Write the CHR image to the selected disk (with sync and progress)
echo "[+] Writing CHR image to /dev/$STORAGE..."
dd if=chr.img of=/dev/$STORAGE bs=4M oflag=sync status=progress

# Enable system request key (SysRq) for forced reboot
echo "[+] Installation done. Rebooting in 5 seconds..."
echo 1 > /proc/sys/kernel/sysrq
sleep 5

# Force reboot using SysRq trigger
echo b > /proc/sysrq-trigger
