#!/bin/bash
err(){ printf "$*\n" >&2; }
die(){ err "$*"; exit 1; }

[ -z "$chrootfile" ] && chrootfile=""
case "$HOST" in
	"archiso") strapcmd="pacstrap"; fstabcmd="genfstab"; chrootcmd="arch-chroot" ;;
	"artixlinux") strapcmd="basestrap" fstabcmd="fstabgen"; chrootcmd="artix-chroot" ;;
	*) die "This host is not booted from the arch install media" ;;
esac

for x in parted ncurses ; do
	pacman --noconfirm --needed -S "$x" || { die "Error at script start: Are you sure you're running this as the root user? Are you sure you have an internet connection?"; }
done


whiptail --defaultno --title "NOTE" --yesno "This Scripts will create\n- Boot (+512M)\n- Swap ( you choose )\n- Root ( you choose )\n- Home (rest of you drive)\n  \nRemember you drive path you want to install!\nExample:\n/dev/xxx\n\n"  15 60 || exit

whiptail --no-cancel --inputbox "Enter a name for your computer [hostname]." 10 60 2> comp

whiptail --defaultno --title "Time Zone select" --yesno "Do you want use the default time zone(Asia/Jakarta)?.\n\nPress no for select your own time zone"  10 60 && echo "Asia/Jakarta" > tz.tmp || tzselect > tz.tmp

whiptail --defaultno --title "Confirmation" --yesno "Sure ?"  10 60 || die "User exited"

grep -q "^ParallelDownloads" /etc/pacman.conf || sed -i "s/#Parallel/Parallel/" /etc/pacman.conf

pacman -Syy

re='^[0-9]+$'
if ! [ ${#SIZE[@]} -eq 2 ] || ! [[ ${SIZE[0]} =~ $re ]] || ! [[ ${SIZE[1]} =~ $re ]] ; then
    SIZE=(12 25);
fi

# Sync clock
timedatectl set-ntp true

uefiformat() {
	GRUBPKG="grub efibootmgr mtools dosfstools"

cat <<EOF | fdisk $(cat drivepath)
g
n
p


+512M
n
p


+${SIZE[0]}G
n
p


+${SIZE[1]}G
n
p


w
EOF
partprobe

yes | mkfs.fat -F32 $(cat drivepath)1
yes | mkfs.ext4 $(cat drivepath)3
yes | mkfs.ext4 $(cat drivepath)4
mkswap $(cat drivepath)2
swapon $(cat drivepath)2
mount $(cat drivepath)3 /mnt
mkdir -p /mnt/boot/efi
mount $(cat drivepath)1 /mnt/boot/efi
mkdir -p /mnt/home
mount $(cat drivepath)4 /mnt/home
}

legacyformat() {
	GRUBPKG="grub"
cat <<EOF | fdisk $(cat drivepath)
o
n
p


+200M
n
p


+${SIZE[0]}G
n
p


+${SIZE[1]}G
n
p


w
EOF
partprobe

yes | mkfs.ext4 $(cat drivepath)1
yes | mkfs.ext4 $(cat drivepath)3
yes | mkfs.ext4 $(cat drivepath)4
mkswap $(cat drivepath)2
swapon $(cat drivepath)2
mount $(cat drivepath)3 /mnt
mkdir -p /mnt/boot
mount $(cat drivepath)1 /mnt/boot
mkdir -p /mnt/home
mount $(cat drivepath)4 /mnt/home
}

usbformat() {
	GRUBPKG="grub efibootmgr mtools dosfstools"
cat <<EOF | fdisk $(cat drivepath)
o
n
p


+100M
n
p

+512M
n
p

+${SIZE[0]}G
n
p


+${SIZE[1]}G
n
p


w
EOF
partprobe

yes | mkfs.fat -F32 $(cat drivepath)2
yes | mkfs.ext4 $(cat drivepath)3
yes | mkfs.ext4 $(cat drivepath)4
mount $(cat drivepath)3 /mnt
mkdir -p /mnt/boot/efi
mount $(cat drivepath)2 /mnt/boot/efi
mkdir -p /mnt/home
mount $(cat drivepath)4 /mnt/home
}

case "$(readlink -f /sbin/init)" in
	*systemd*) ;;
	# NOTE: untested
	# *runit*) EXPKG="runit elogind-runit networkmanager-runit" ;;
	# *openrc*) EXPKG="openrc elogind-openrc networkmanager-openrc" ;;
	# *s6*) EXPKG="s6-base elogind-s6 networkmanager-s6" ;;
	# *66*) EXPKG="66 elogind-66" ;;
esac

{ ls /sys/firmware/efi/efivars >/dev/null 2>&1 && uefiformat; } || legacyformat

lsblk && sleep 10s

whiptail --defaultno --title "Confirmation" --yesno "SURE ?"  10 60 || die "User exited"
pacman -Q artix-keyring >/dev/null 2>&1 && pacman --noconfirm -S artix-keyring >/dev/null 2>&1
pacman -Sy --noconfirm archlinux-keyring

procvendor="$(grep -r "model name" /proc/cpuinfo | uniq | cut -d ':' -f 2 | grep -oi "Intel\|AMD")"
gpuvendor="$(lspci | grep -i 'vga\|2d\|3d' | grep -oi "intel\|amd\|nvidia\|parallels")"

[ "$procvendor" = "Intel" ] && PROC="intel-ucode" || PROC="amd-ucode"

case $gpuvendor in
	"Intel") GPU="xf86-video-intel" ;;
	"AMD") GPU="xf86-video-amdgpu" ;;
	"ATI") GPU="xf86-video-ati" ;;
	"Parallels") GPU="xf86-video-vesa" ;;
	#	"") GPU="nvidia nvidia-utils nvidia-settings"
	#	"") GPU="xf86-video-vmware"
	#	"") GPU="xf86-video-nouveau"
esac

$strapcmd /mnt base base-devel linux linux-headers linux-firmware\
	reflector chezmoi $PROC $GPU neovim git

[ ! -d "/mnt/etc" ] && mkdir -p /mnt/etc
[ -f "/mnt/etc/fstab" ] && rm /mnt/etc/fstab
[ -f "/mnt/etc/hostname" ] && rm /mnt/etc/hostname

$fstabcmd -U /mnt >> /mnt/etc/fstab

[ "$HOST" = "archiso" ] && cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist

[ "$HOST" = "artixlinux" ] && cp /etc/pacman.d/mirrorlist-arch /mnt/etc/pacman.d/mirrorlist-arch

cp "$chrootfile" /mnt/chroot && $chrootcmd /mnt bash chroot.sh
