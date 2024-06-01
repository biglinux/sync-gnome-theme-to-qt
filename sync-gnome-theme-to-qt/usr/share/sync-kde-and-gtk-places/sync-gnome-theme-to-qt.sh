#!/bin/sh
#
# From gtk gnome theme to kvantum theme
# By Bruno Goncalves < www.biglinux.com.br >
# Create in: 2023/02/08

# Change kdeglobals fonts based in gnome font configuration
# Commented because qt automatic detect, but if using desktop without automatic detect
# Just uncomment next lines
# # Read Gnome font config and convert in variables
# while IFS= read -r Line; do
#     # if [[ $Line =~ ^document-font-name= ]]; then
#         #document_font_name=${Line/*=}
#         # document_font_name=${document_font_name//\'}
#         # document_font_size=${document_font_name##* }
#         # document_font_name=${document_font_name% *}
#         # document_font_style=${document_font_name##* }
#         # echo $document_font_size
#         # echo $document_font_name
#         # echo $document_font_style
# 
#     if [[ $Line =~ ^font-name= ]]; then
#         font_name=${Line/*=}
#         font_name=${font_name//\'}
#         font_size=${font_name##* }
#         font_name=${font_name% *}
#         font_style=${font_name##* }
#         # echo $font_size
#         # echo $font_name
#         # echo $font_style
#         
#     elif [[ $Line =~ ^monospace-font-name= ]]; then
#         monospace_font_name=${Line/*=}
#         monospace_font_name=${monospace_font_name//\'}
#         monospace_font_size=${monospace_font_name##* }
#         monospace_font_name=${monospace_font_name% *}
#         monospace_font_style=${monospace_font_name##* }
#         # echo $monospace_font_size
#         # echo $monospace_font_name
#         # echo $monospace_font_style
# 
#     elif [[ $Line =~ ^titlebar-font= ]]; then
#         titlebar_font_name=${Line/*=}
#         titlebar_font_name=${titlebar_font_name//\'}
#         titlebar_font_size=${titlebar_font_name##* }
#         titlebar_font_name=${titlebar_font_name% *}
#         titlebar_font_style=${titlebar_font_name##* }
#         # echo $titlebar_font_size
#         # echo $titlebar_font_name
#         # echo $titlebar_font_style    
#     fi
# done <<< "$(dconf dump /org/gnome/desktop/ | grep -e 'document-font-name=' -e 'font-name=' -e 'monospace-font-name=' -e 'titlebar-font=')"
# 
# # Apply font changes in kdeglobals file
# sed -i "s|^fixed=.*|fixed=$monospace_font_name,$monospace_font_size,-1,5,50,0,0,0,0,0,$monospace_font_style|g; \
#     s|^font=.*|font=$font_name,$font_size,-1,5,63,0,0,0,0,0,$font_style|g; \
#     s|^menuFont=.*|menuFont=$font_name,$font_size,-1,5,63,0,0,0,0,0,$font_style|g; \
#     s|^smallestReadableFont=.*|smallestReadableFont=$font_name,$font_size,-1,5,63,0,0,0,0,0,$font_style|g; \
#     s|^toolBarFont=.*|toolBarFont=$font_name,$font_size,-1,5,63,0,0,0,0,0,$font_style|g; \
#     s|^activeFont=.*|activeFont=$titlebar_font_name,$titlebar_font_size,-1,5,63,0,0,0,0,0,$titlebar_font_style|g" ~/.config/kdeglobals

# Only change if not in KDE
if [[ "$XDG_SESSION_DESKTOP" != "KDE" ]]; then
    ColorScheme="$(dconf read /org/gnome/desktop/interface/color-scheme)"
    KvantumTheme="$(grep 'theme=' ~/.config/Kvantum/kvantum.kvconfig)"

    if [ "$ColorScheme" = "'prefer-dark'" -a "$KvantumTheme" != "theme=BigAdwaitaRoundDark" ]; then
        IconTheme="$(dconf read /org/gnome/desktop/interface/icon-theme)"
        mkdir -p ~/.config/Kvantum/
        echo '[General]
    theme=BigAdwaitaRoundDark' > ~/.config/Kvantum/kvantum.kvconfig

        # Copy the configuration file for the dark theme
        cp -f /usr/share/sync-kde-and-gtk-places/biglinux-dark ~/.config/kdeglobals

        IconFolder="$(ls -d /usr/share/icons/*/ ~/.local/share/icons/*/ 2> /dev/null | grep -i dark | grep -im1 "/${IconTheme//\'/}")"
        IconFolderClean1=${IconFolder%/}
        IconFolderClean2=${IconFolderClean1##*/}
        if [ "$IconFolderClean2" != "" ]; then
            dconf write /org/gnome/desktop/interface/icon-theme "'$IconFolderClean2'"
        fi

        exit 0
    fi

    if [ "$ColorScheme" != "'prefer-dark'" -a "$KvantumTheme" != "theme=BigAdwaitaRound" ]; then
        IconTheme="$(dconf read /org/gnome/desktop/interface/icon-theme)"
        mkdir -p ~/.config/Kvantum/
        echo '[General]
    theme=BigAdwaitaRound' > ~/.config/Kvantum/kvantum.kvconfig

        # Copy the configuration file for the non-dark theme
        cp -f /usr/share/sync-kde-and-gtk-places/biglinux ~/.config/kdeglobals

        IconThemeWithoutDark="$(echo $IconTheme | sed 's|-dark||gi;s|dark||gi')"
        IconFolder="$(ls -d /usr/share/icons/*/ ~/.local/share/icons/*/ 2> /dev/null | grep -vi dark | grep -im1 "/${IconThemeWithoutDark//\'/}")"
        IconFolderClean1=${IconFolder%/}
        IconFolderClean2=${IconFolderClean1##*/}
        if [ "$IconFolderClean2" != "" ]; then
            dconf write /org/gnome/desktop/interface/icon-theme "'$IconFolderClean2'"
        fi

        exit 0
    fi

fi
