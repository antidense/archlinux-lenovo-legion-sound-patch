#!/bin/bash
uname -a
version=$(uname -r | cut -d'-' -f1)
echo "$version"
read -p "We will compile for $version. Do you want to continue? (y/n) " choice
case "$choice" in
  y|Y ) echo "OK, continuing...";;
  n|N ) echo "Aborting."; exit 1;;
  * ) echo "Invalid choice, aborting."; exit 1;;
esac
cd /home/$USER/
mkdir kernel-build-$version
cd kernel-build-$version
wget -nc https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-$version.tar.xz
wget -nc https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-$version.tar.sign
wget -O lenovo-7i-gen7-sound-6.2.0-rc3-0.0.5b-002.patch  https://bugzilla.kernel.org/attachment.cgi?id=303828
gpg2 --list-packets linux-$version.tar.sign

read -p "What is the current keyid listed above? It should be something like 38........93E " keyID
gpg2 --recv-keys $keyID
unxz linux-$version.tar.xz
gpg2 --tofu-policy good $keyID
gpg2 --verify linux-$version.tar.sign linux-$version.tar
gpg2 --trust-model tofu --verify linux-$version.tar.sign linux-$version.tar

read -p "Do you want to continue? (y/n) " choice
case "$choice" in
  y|Y ) echo "OK, continuing...";;
  n|N ) echo "Aborting."; exit 1;;
  * ) echo "Invalid choice, aborting."; exit 1;;
esac


tar -xvf linux-$version.tar
chown -R $USER:$USER linux-$version
cd linux-$version
make mrproper
zcat /proc/config.gz  > .config
patch -p1 < ./lenovo-7i-gen7-sound-6.2.0-rc3-0.0.5b-002.patch 
make -j$(nproc)
make modules
sudo make modules_install
make bzImage
sudo cp -v arch/x86/boot/bzImage /boot/vmlinuz-linux-soundfix

# Check if the linux-soundfix.preset file exists
if [ ! -f /etc/mkinitcpio.d/linux-soundfix.preset ]; then
    # Copy the linux.preset file to linux-soundfix.preset
    sudo cp /etc/mkinitcpio.d/linux.preset /etc/mkinitcpio.d/linux-soundfix.preset
    # Change the kernel and initramfs file names in linux-soundfix.preset
    sudo sed -i 's/vmlinuz-linux/vmlinuz-linux-soundfix/' /etc/mkinitcpio.d/linux-soundfix.preset
    sudo sed -i 's/initramfs-linux.img/initramfs-linux-soundfix.img/' /etc/mkinitcpio.d/linux-soundfix.preset
    sudo sed -i 's/initramfs-linux-fallback.img/initramfs-linux-soundfix-fallback.img/' /etc/mkinitcpio.d/linux-soundfix.preset
fi


sudo mkinitcpio -p linux-soundfix
echo "Generation complete. Now you need to update your bootloader."
