#!/bin/sh
#
# From gtk gnome theme to kvantum theme
# By Bruno Goncalves < www.biglinux.com.br >
# 2023/02/08

ColorScheme="$(dconf read /org/gnome/desktop/interface/color-scheme)"
KvantumTheme="$(grep 'theme=' ~/.config/Kvantum/kvantum.kvconfig)"

if [ "$ColorScheme" = "'prefer-dark'" -a "$KvantumTheme" != "theme=KvLibadwaitaDark" ]; then
    IconTheme="$(dconf read /org/gnome/desktop/interface/icon-theme)"
    mkdir -p ~/.config/Kvantum/
    echo '[General]
theme=KvLibadwaitaDark' > ~/.config/Kvantum/kvantum.kvconfig

    IconFolder="$(ls -d /usr/share/icons/*/ ~/.local/share/icons/*/ 2> /dev/null | grep -i dark | grep -im1 "/${IconTheme//\'/}")"
    IconFolderClean1=${IconFolder%/}
    IconFolderClean2=${IconFolderClean1##*/}
    if [ "$IconFolderClean2" != "" ]; then
        dconf write /org/gnome/desktop/interface/icon-theme "'$IconFolderClean2'"
    fi

    exit 0
fi

if [ "$ColorScheme" != "'prefer-dark'" -a "$KvantumTheme" != "theme=KvLibadwaita" ]; then
    IconTheme="$(dconf read /org/gnome/desktop/interface/icon-theme)"
    mkdir -p ~/.config/Kvantum/
    echo '[General]
theme=KvLibadwaita' > ~/.config/Kvantum/kvantum.kvconfig

    IconThemeWithoutDark="$(echo $IconTheme | sed 's|-dark||gi;s|dark||gi')"
    IconFolder="$(ls -d /usr/share/icons/*/ ~/.local/share/icons/*/ 2> /dev/null | grep -vi dark | grep -im1 "/${IconThemeWithoutDark//\'/}")"
    IconFolderClean1=${IconFolder%/}
    IconFolderClean2=${IconFolderClean1##*/}
    if [ "$IconFolderClean2" != "" ]; then
        dconf write /org/gnome/desktop/interface/icon-theme "'$IconFolderClean2'"
    fi

    exit 0
fi
