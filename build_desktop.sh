#!/bin/bash
set -ex

# Install required packages if host Debian/Ubuntu
if [[ -d /var/lib/apt/ ]] ; then
    cp /etc/apt/sources.list /etc/apt/sources.list.d/noble.list
    sed -i s/jammy/noble/g /etc/apt/sources.list.d/noble.list
    apt update
    apt -t noble install arch-install-scripts pacman-package-manager archlinux-keyring makepkg -y
    apt -t jammy install wget qemu-user-static binfmt-support wget unzip qemu-utils -y
fi

mkdir -p misilix

# Create a temporary pacman.conf for bootstrapping
[[ -f pacman.conf ]] || cat > pacman.conf << EOF
[options]
Architecture = aarch64
Color
ILoveCandy
VerbosePkgLists
ParallelDownloads = 5
SigLevel = Never TrustAll

[core]
Server = http://mirror.archlinuxarm.org/\$arch/\$repo/

[extra]
Server = http://mirror.archlinuxarm.org/\$arch/\$repo/

[alarm]
Server = http://mirror.archlinuxarm.org/\$arch/\$repo/

[aur]
Server = http://mirror.archlinuxarm.org/\$arch/\$repo/

[pkgbuild-ci]
SigLevel = Optional TrustAll
Server = https://github.com/misile00/misilix/releases/download/pkgbuild-ci

EOF

# Initialize pacman keyring and populate Arch Linux keyring
pacman-key --init && pacman-key --populate archlinux

# Create rootfs
[[ -f misilix/etc/os-release ]] || cat pkglist_desktop.txt | pacstrap -MGC ./pacman.conf misilix -

cat > misilix/boot/config.txt << EOF
# For more options and information see
# http://rpf.io/configtxt
# Some settings may impact device functionality. See link above for details

initramfs initramfs-linux.img followkernel

# uncomment if you get no picture on HDMI for a default "safe" mode
#hdmi_safe=1

# uncomment the following to adjust overscan. Use positive numbers if console
# goes off screen, and negative if there is too much border
#overscan_left=16
#overscan_right=16
#overscan_top=16
#overscan_bottom=16

# uncomment to force a console size. By default it will be display's size minus
# overscan.
#framebuffer_width=1280
#framebuffer_height=720

# uncomment if hdmi display is not detected and composite is being output
#hdmi_force_hotplug=1

# uncomment to force a specific HDMI mode (this will force VGA)
#hdmi_group=1
#hdmi_mode=1

# uncomment to force a HDMI mode rather than DVI. This can make audio work in
# DMT (computer monitor) modes
#hdmi_drive=2

# uncomment to increase signal to HDMI, if you have interference, blanking, or
# no display
#config_hdmi_boost=4

# uncomment for composite PAL
#sdtv_mode=2

#uncomment to overclock the arm. 700 MHz is the default.
#arm_freq=800
#core_freq=250
#sdram_freq=400

# Uncomment some or all of these to enable the optional hardware interfaces
#dtparam=i2c_arm=on
#dtparam=i2s=on
#dtparam=spi=on

# Uncomment this to enable infrared communication.
#dtoverlay=gpio-ir,gpio_pin=17
#dtoverlay=gpio-ir-tx,gpio_pin=18

# Additional overlays and parameters are documented /boot/overlays/README

# Enable audio (loads snd_bcm2835)
dtparam=audio=on

# Uncomment to enable bluetooth
#dtparam=krnbt=on

# Early boot delay in the hope monitors are initialised enough to provide EDID
bootcode_delay=1
 
# We need this to be 32Mb to support VCHI services and drivers which use them
# but this isn't used by mainline VC4 driver so reduce to lowest supported value
# You need to set this to at least 80 for using the camera
# gpu_mem=32

# Automatically load overlays for detected cameras
camera_auto_detect=1

# Automatically load overlays for detected DSI displays
display_auto_detect=1

# Enable DRM VC4 V3D driver
dtoverlay=vc4-kms-v3d
max_framebuffers=2

# Run in 64-bit mode
arm_64bit=1

# Disable compensation for displays with overscan
disable_overscan=1

[cm4]
# Enable host mode on the 2711 built-in XHCI USB controller.
# This line should be removed if the legacy DWC2 controller is required
# (e.g. for USB device mode) or if USB support is not required.
otg_mode=1

[pi4]
# Run as fast as firmware / board allows
arm_boost=1

EOF

if which service ; then
    service binfmt-support start
fi

# Configure system
echo -e "allowed_users=anybody\nneeds_root_rights=yes" > /etc/X11/Xwrapper.config
cp usr/local/resize-fs.sh misilix/usr/local/
cp -r etc/* misilix/etc/
chmod a+x misilix/etc/profile.d/pacman-init.sh misilix/usr/local/resize-fs.sh
chroot misilix /usr/bin/systemctl enable lightdm.service resize-fs.service NetworkManager.service sshd.service avahi-daemon.service
sed -i s/#NTP=/NTP=0.pool.ntp.org/g misilix/etc/systemd/timesyncd.conf
echo -e "\nC.UTF-8 UTF-8\nen_US.UTF-8 UTF-8\nen_US ISO-8859-1" >> misilix/etc/locale.gen
echo "LANG=en_US.UTF-8" > misilix/etc/locale.conf
echo "KEYMAP=trq" > misilix/etc/vconsole.conf
echo -e "nameserver 8.8.8.8\nnameserver 8.8.8.4" > misilix/etc/resolv.conf
sed -i "s/Arch Linux/Misilix Linux/g" misilix/etc/issue
sed -i "s/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/g" misilix/etc/sudoers
echo "Defaults env_reset,pwfeedback" > misilix/etc/sudoers.d/10-pwfeedback
chroot misilix /usr/bin/locale-gen

# Create default user accounts
chroot misilix /bin/bash -c "useradd alarm -mUG wheel,video,tty,audio -m -u 1000"
echo -e "root\nroot\n" | chroot misilix /bin/bash -c "passwd root"
echo -e "alarm\nalarm\n" | chroot misilix /bin/bash -c "passwd alarm"
find misilix/var/log/ -type f | xargs rm -f
chroot misilix /bin/bash -c "pacman -Scc --noconfirm"

# Create image
size=$(echo "($(du -s "misilix" | cut -f 1) * 1.5) / 1" | bc)
qemu-img create "misilix-desktop.img" ${size}k
parted -s "misilix-desktop.img" mklabel msdos
parted -s "misilix-desktop.img" mkpart primary fat32 0 300M 
parted -s "misilix-desktop.img" mkpart primary btrfs 301M 100%

# Format image
losetup -d /dev/loop0 || true
loop=$(losetup --partscan --find --show "misilix-desktop.img" | grep "/dev/loop")
mkfs.vfat ${loop}p1 -n "BOOT_MSL"
mkfs.btrfs ${loop}p2 -L "ROOT_MSL"

# Copy boot partition
mount ${loop}p1 /mnt
cp -prfv misilix/boot/* /mnt/ 2>&1 > /dev/null
sync
umount -f /mnt

# Copy rootfs partition
mount ${loop}p2 /mnt
cp -prfv misilix/* /mnt/ 2>&1 > /dev/null
sync
umount /mnt
losetup -d /dev/loop0
xz -T0 -9 misilix-desktop.img
# Done