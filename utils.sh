#!/bin/sh

error() { clear; printf "ERROR:\\n%s\\n" "$1" >&2; exit 1;}

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
            if [[ -f /etc/os-release || \
		  -f /etc/lsb-release  ]]; then
              for file in /etc/os-release /etc/lsb-release ;do
		  source "$file" && break
	      done
              distro="${NAME:-${DISTRIB_DESCRIPTION}}"
            elif type -p lsb_release >/dev/null; then
		    distro=$(lsb_releae -sd)
            fi
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
    export RARBS_DISTRO="$distro"
}

installpkg() {
    case "$OS" in
        "macOS") brew install "$1" >/dev/null 2>&1 ;;
        "Linux")
            case "$distro" in
		 Arch*|Manjaro*|Artix*)
                    pacman --noconfirm --needed -S "$1" >/dev/null 2>&1 ;;
            esac
            ;;
    esac ;}


installdmi(){
    if [[ "$OS" == "macOS" ]]; then
        dmiurl="https://github.com/acidanthera/dmidecode/releases/download/3.3b/dmidecode-mac-3.3b.zip"
        curl -Ls $dmiurl -o /tmp/dmidecode.zip
        unzip /tmp/dmidecode.zip -d /usr/local/bin
    else
        installpkg dmidecode
    fi
}

getChassis(){ \
    [ -x "$(command -v "dmidecode")" ] || installdmi
    #https://superuser.com/questions/877677/programatically-determine-if-an-script-is-being-executed-on-laptop-or-desktop
    # Notebook - Desktop
    is_chassis=$(dmidecode -t chassis | grep "Type:" | cut -d: -f2 | tr -d ' ')
    [ -z "$is_chassis" ] && error "dmidecode: need run as root"
    #TODO: if linux and systemd uses `hostnamectl chassis'
    # TODO: Add desktopp
    case "$is_chassis" in
        "Notebook") chassis="Laptop" ;;
        "Unknown"|"Other") chassis="Virtual Machine" ;;
        *) error "Unknown Chassis Type $is_chassis"
    esac
    export RARBS_CHASSIS="$chassis"
}

getOS() { \
    case $kernel_name in
        Darwin) 
                OS=$darwin_name
                ;;
        Linux|GNU*) OS=Linux ;;
        *) error "Unknown OS: '$kernel_name'" ;;
    esac
    export RARBS_OS="$OS"
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
