#!/usr/bin/env bash

[ -f .env ] && source .env

THEME_NAME="bgrt"
THEMES_DIR=/boot/grub/themes
GRUB_MKFONT="grub-mkfont"
GRUB_CONFIG=/etc/default/grub
GRUB_UPDATE="sudo update-grub"

echo "Installing ${THEME_NAME} GRUB2 theme ..."
echo ""

let BAR_WIDTH=${BAR_WIDTH:-"768"} BAR_WIDTH_HALF=BAR_WIDTH/2
let BAR_HEIGHT=${BAR_HEIGHT:-"8"} BAR_HEIGHT_HALF=BAR_HEIGHT/2
MENU_FONT_SIZE="${MENU_FONT_SIZE:-"24"}"
TERMINAL_FONT_SIZE="${TERMINAL_FONT_SIZE:-"12"}"

BACK_COLOR="${BACK_COLOR:-"000000"}"
ITEM_COLOR="${ITEM_COLOR:-"A0A0A0"}"
SELECTION_COLOR="${SELECTION_COLOR:-"FFFFFF"}"
BAR_COLOR="${BAR_COLOR:-"505050"}"
BAR_HIGHLIGHT="${BAR_HIGHLIGHT:-"A0A0A0"}"

source /etc/os-release
for os in ${ID_LIKE}; do ID=${os}; done
case "${ID}" in
	"debian")
		echo "Debian-based distribution found."
		MENU_FONT="${MENU_FONT:-"/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"}"
		TERMINAL_FONT="${TERMINAL_FONT:-"/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf"}"
    	;;
	"rhel"|"fedora")
		echo "RHEL-based distribution found."
		THEMES_DIR=/boot/grub2/themes
		GRUB_MKFONT="grub2-mkfont"
		MENU_FONT="${MENU_FONT:-"/usr/share/fonts/dejavu-sans-fonts/DejaVuSans.ttf"}"
		TERMINAL_FONT="${TERMINAL_FONT:-"/usr/share/fonts/dejavu-sans-mono-fonts/DejaVuSansMono.ttf"}"
		GRUB_UPDATE="sudo grub2-mkconfig -o /etc/grub2-efi.cfig"
    	;;
	*)
    	echo "Warning! Unsopported distribution. Fonts have to be explicitly defined."
		if ! [ -n ${MENU_FONT} ]; then
			echo "MENU_FONT undefined. Aborting."
			exit 1
		fi
		if ! [ -n ${TERMINAL_FONT} ]; then
			echo "TERMINAL_FONT undefined. Aborting."
			exit 1
		fi
    	;;
esac

mkdir -p ${THEMES_DIR}/${THEME_NAME}

echo "Generating PNG images ..."
if [[ ! -r /sys/firmware/acpi/bgrt/image ]]; then
	echo "/sys/firmware/acpi/bgrt/image not found. Not a valid UEFI system. Aborting."
	exit 1
fi
if ! [ -x $(command -v convert) ]; then
	echo "convert command not found. Please install imagemagick. Aborting."
	exit 1
fi
convert -verbose -define colorspace:auto-grayscale=false -type truecolor -size ${BAR_WIDTH}x${BAR_HEIGHT} xc:\#${BAR_COLOR} PNG24:${THEMES_DIR}/${THEME_NAME}/bar_c.png
convert -verbose -define colorspace:auto-grayscale=false -type truecolor -size ${BAR_WIDTH}x${BAR_HEIGHT} xc:\#${BAR_HIGHLIGHT} PNG24:${THEMES_DIR}/${THEME_NAME}/bar_hl_c.png
convert -verbose -define colorspace:auto-grayscale=false -type truecolor /sys/firmware/acpi/bgrt/image PNG24:${THEMES_DIR}/${THEME_NAME}/image.png
echo "Done."

echo "Setting image offsets ..."
IMAGE_LEFT=$(cat /sys/firmware/acpi/bgrt/xoffset)
IMAGE_TOP=$(cat /sys/firmware/acpi/bgrt/yoffset)
echo "Done."

if ! [ -x $(command -v ${GRUB_MKFONT}) ]; then
	echo "${GRUB_MKFONT} command not found. Aborting."
	exit 1
fi

echo "Generating menu font from ${MENU_FONT} ..."
if [ ! -f ${MENU_FONT} ]; then
	echo "The menu font file not found. Aborting."
	exit 1
fi
${GRUB_MKFONT} --force-autohint --name="Menu" --output=${THEMES_DIR}/${THEME_NAME}/menu.pf2 --size=${MENU_FONT_SIZE} --verbose ${MENU_FONT}
echo "Done."

echo "Generating terminal font from ${TERMINAL_FONT} ..."
if [ ! -f ${TERMINAL_FONT} ]; then
	echo "The terminal font file not found. Aborting."
	exit 1
fi 
${GRUB_MKFONT} --force-autohint --name="Terminal" --output=${THEMES_DIR}/${THEME_NAME}/terminal.pf2 --size=${TERMINAL_FONT_SIZE} --verbose ${TERMINAL_FONT}
echo "Done."

echo "Generating theme file ..."
if ! [ -x $(command -v envsubst) ]; then
	echo "envsubst command not found. Please install gettext-base. Aborting."
	exit 1
fi
export BAR_WIDTH BAR_WIDTH_HALF BAR_HEIGHT BAR_HEIGHT_HALF \
	MENU_FONT_SIZE TERMINAL_FONT_SIZE \
	BACK_COLOR ITEM_COLOR SELECTION_COLOR BAR_COLOR BAR_HIGHLIGHT \
	IMAGE_LEFT IMAGE_TOP
envsubst < theme.txt.tmpl > ${THEMES_DIR}/${THEME_NAME}/theme.txt
echo "Done."

echo ""
echo "Installation completed. To select this theme, add the following line to ${GRUB_CONFIG}"
echo "GRUB_THEME=${THEMES_DIR}/${THEME_NAME}/theme.txt"
echo "Then update GRUB2 config with"
echo "${GRUB_UPDATE}"
