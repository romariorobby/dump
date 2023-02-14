
userdrive="$(cat drivepath.tmp)"
usertz="$(cat usertz.tmp)"

echo "Please enter a password for root account.."
passwd

grep -q "^Color" /etc/pacman.conf || sed -i "s/^#Color$/Color/" /etc/pacman.conf
grep -q "^ParallelDownloads" /etc/pacman.conf || sed -i "s/#Parallel/Parallel/" /etc/pacman.conf
grep -q "ILoveCandy" /etc/pacman.conf || sed -i "/#VerbosePkgLists/a ILoveCandy" /etc/pacman.conf
ln -sf /usr/share/zoneinfo/$usertz /etc/localtime
hwclock --systohc

echo "LANG=en_US.UTF-8" >> /etc/locale.conf
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "en_US ISO-8859-1" >> /etc/locale.gen

printf "127.0.0.1\tlocalhost
::1\t\tlocalhost
127.0.0.1\t$(cat /etc/hostname).localdomain\t$(cat /etc/hostname)\n" >> /etc/hosts

locale-gen

pacman --noconfirm --needed -Syu networkmanager 
if [ "$(readlink -f /sbin/init)" = "*systemd*" ]; then
	echo "enabled networkmanager"
	systemctl enable NetworkManager
	systemctl enable sshd
else
	echo "NOTE: check your init system how to enable daemon"
fi

# if $USB {{{
# sed -i "s/^HOOKS/#HOOKS/g" && echo "HOOKS=(base udev autodetect mdconf block filesytems keyboard fsck)" >> /etc/mkinitcpio.conf
# mkinitcpio -p linux
# [ ! -f /etc/systemd/journald.conf.d/usbstick.conf ] && mkdir -p /etc/systemd/journald.conf.d && printf '[Journal]
# Storage=volatile
# RuntimeMaxUse=30M' > /etc/systemd/journald.conf.d/usbstick.conf
# end }}}

if [ "$(ls /sys/firmware/efi/efivars >/dev/null 2>&1)" ]; then
	# if $USB
	# GRUBARGS="--removable --recheck"
	# end
	grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB $GRUBARGS
else
	grub-install --target=i386-pc "$userdrive"
fi

grub-mkconfig -o /boot/grub/grub.cfg
