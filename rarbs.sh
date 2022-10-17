#!/bin/sh

#[ -f "/etc/artix-release" ] && echo "Using Artix"
#[ -f "/etc/arch-release" ] && echo "Using Vanilla Arch"
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
echo "test forge"
export RARBS_DIR="$SCRIPT_DIR"
source $RARBS_DIR/utils.sh

[ -z "$prechrootfile" ] && prechrootfile="$RARBS_DIR/arch/prechroot.sh"

### Picking
modepick(){ \
    is_liveusb
    #liveusb=1
    [[ -n "$liveusb" ]] && mpick="I" ||
	    mpick=$(dialog --no-cancel \
                       --backtitle "RARBS Type Picking" \
                       --radiolist "Select RARBS Mode: " 10 80 3 \
                       R "(Re)install (Packages)" on \
                       P "Post Install" on 3>&1 1>&2 2>&3 3>&1)

    gochroot(){ bash $prechrootfile || error "Exited"; }
    # gochroot(){ echo "$prechrootfile" || error "Exited"; }
    case $mpick in
	"I") namempick="Installer"
             dialog --defaultno \
                    --title "PRE-CHROOT" \
                    --yesno "Go to Pre-chroot?" 6 30 && gochroot
            ;;
        "R") namempick="(Re)install (Packages)" ;;
	"P") namempick="Post Install" ;;
    esac

}


getUname
getOS
getDistro
getChassis
#modepick
gochroot(){ bash $prechrootfile; }
gochroot
echo $namepick
echo "OS: $OS"
echo "OS: $RARBS_OS"
echo "CHASSIS: $chassis"
echo "DISTRO: $distro"
echo "DIR BASE: $DIRS"
echo "DIR BASE: $SCRIPT_DIR"
# TODO: Add long argument with --arguments
#while getopts ":a:r:b:p:s:g:h:d" o; do case "${o}" in
#	h) printf "Optional arguments for custom use:\\n  -r: Dotfiles repository (local file or url)\\n  -p: Dependencies and programs csv (local file or url)\\n  -s: Homebrew Source (tap)\\n  -a: AUR helper (must have pacman-like syntax) (paru by default)\\n  -h: Show this message\\n" && exit 1 ;;
#	r) dotfilesrepo=${OPTARG} && chezmoi git ls-remote "$dotfilesrepo" || exit 1 ;;
#	b) repobranch=${OPTARG} ;;
#	p) progsfile=${OPTARG} ;;
#	s) brewtapfile=${OPTARG} ;;
#	a) aurhelper=${OPTARG} ;;
#	g) gpgfile=${OPTARG} ;;
#	d) dummy ;;
#	*) printf "Invalid option: -%s\\n" "$OPTARG" && exit 1 ;;
#esac done
