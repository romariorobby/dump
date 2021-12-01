#!/bin/sh

#[ -f "/etc/artix-release" ] && echo "Using Artix"
#[ -f "/etc/arch-release" ] && echo "Using Vanilla Arch"

[ -z "$prechrootfile" ] && prechrootfile="arch/prechroot.sh" || prechrootfile="https://raw.githubusercontent.com/$username/$reponame/$branch/prechroot"

getUname(){
    IFS=" " read -ra uname <<< "$(uname -srm)"

    kernel_name="${uname[0]}"
    kernel_version="${uname[1]}"
    kernel_machine="${uname[2]}"
    if [ "$kernel_name" == "Darwin" ];then
        export SYSTEM_VERSION_COMPAT=0
        IFS=$'\n' read -d "" -ra sw_vers <<< "$(awk -F'<|>' '/key|string/ {print $3}' \
                                "/System/Library/CoreServices/SystemVersion.plist")"
            for ((i=0;i<${#sw_vers[@]};i+=2)) {
                case ${sw_vers[i]} in
                    ProductName)          darwin_name=${sw_vers[i+1]} ;;
                    ProductVersion)       osx_version=${sw_vers[i+1]} ;;
                    ProductBuildVersion)  osx_build=${sw_vers[i+1]}   ;;
                esac
            }
    fi
}

getDistro(){
    case $OS in
        Linux)
            if [[ -f /etc/os-release ]]; then
                    source /etc/os-release
            fi
            distro="${NAME}"
	    [ -f "/etc/artix-release" ] && distro="Artix Linux"
            ;;
        "macOS"|"Mac OS X")
            case $osx_version in
                10.15*) codename="macOS Catalina" ;;
                10.16*|11.*) codename="macOS Big Sur";;
                12.*) codename="macOS Monterey";;
                *) codename="macOS" ;;
            esac
            distro="$codename $osx_version $osx_build"
    esac
}

getChassis(){ \
    [ -x "$(command -v "dmidecode")" ] || installdmi
    #https://superuser.com/questions/877677/programatically-determine-if-an-script-is-being-executed-on-laptop-or-desktop
    # Notebook - Desktop
    is_chassis=$(dmidecode -t chassis | grep "Type:" | cut -d: -f2 | tr -d ' ')
    # TODO: Add desktopp
    case "$is_chassis" in
        "Notebook") chassis="Laptop" ;;
        "Unknown"|"Other") chassis="Virtual Machine" ;;
        *) error "Unknown Chassis Type $is_chassis"
    esac
}

getOS() { \
    case $kernel_name in
        Darwin) 
                OS=$darwin_name
                ;;
        Linux|GNU*) OS=Linux ;;
        *) error "Unknown OS: '$kernel_name'" ;;
    esac
}

is_liveusb(){
	liveusb=""
	[[ "$OS" != "Linux" ]] && return
	if cat /proc/1/cgroup | tail -1 | grep -q "container"; then
		echo "It's not running live installer"
		# error "It's not running live installer"
	else
		full_fs=$(df ~ | tail -1 | awk '{print $1;}')  # /dev/sda1
		fs=$(basename $full_fs)                        # sda1
		if grep -q "$fs" /proc/partitions; then
			echo "It's not running live installer"
			# error "It's not running live installer"
		else
			#lsblk -no "type" | grep "rom\|loop" && liveusb=1
			liveusb=1
			# dialog --infobox "Entering Pre-chroot" 10 50
		fi
	fi

}

### Picking
modepick(){ \
    is_liveusb
    # if [[ "$distro" == "Arch Linux" || -f "/etc/artix-release"]]; then
    [[ -n "$liveusb" ]] && mpick="I" ||
	    mpick=$(dialog --no-cancel \
                       --backtitle "RARBS Type Picking" \
                       --radiolist "Select RARBS Mode: " 10 80 3 \
                       R "(Re)install (Packages)" on \
                       P "Post Install" on 3>&1 1>&2 2>&3 3>&1)

    #gochroot(){ curl -Ls "$prechrootfile" > prechroot && bash prechroot || error "Exited"; }
    case $mpick in
	"I") namempick="Installer"
             dialog --defaultno \
                    --title "PRE-CHROOT" \
                    --yesno "Go to Pre-chroot?" 6 30 && echo "Go chroot" || modepick
            ;;
        "R") namempick="(Re)install (Packages)" ;;
	"P") namempick="Post Install" ;;
    esac

}

getUname
getOS
getDistro
modepick
echo $namepick
case "$distro" in
    "Arch Linux"|"Artix Linux") bash arch/prechroot.sh ;;
esac
