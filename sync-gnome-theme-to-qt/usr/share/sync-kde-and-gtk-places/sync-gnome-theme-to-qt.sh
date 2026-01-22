#!/bin/sh

# Function to check if current theme is dark
is_dark_theme() {
    if [[ "$XDG_CURRENT_DESKTOP" = *"Cinnamon" ]]; then
        local current_theme=$(dconf read /org/cinnamon/desktop/interface/gtk-theme)
        # Remove quotes from theme name
        current_theme=${current_theme//\'/}
        
        # Check if it's a Big- theme
        if [[ "$current_theme" == Big-* ]]; then
            # If doesn't have Light, it's dark
            [[ "$current_theme" != *Light ]] && return 0
            return 1
        else
            # For other themes, check for dark in name
            [[ "$current_theme" == *dark* ]] && return 0
            return 1
        fi
    elif [[ "$XDG_CURRENT_DESKTOP" == "XFCE" ]] || [[ "$XDG_SESSION_DESKTOP" == "xfce" ]]; then
        # XFCE theme check
        local current_theme=$(xfconf-query -c xsettings -p /Net/ThemeName 2>/dev/null)
        [[ "$current_theme" == *dark* ]] || [[ "$current_theme" == *Dark* ]] && return 0
        return 1
    else
        # GNOME color scheme check
        local color_scheme=$(dconf read /org/gnome/desktop/interface/color-scheme)
        [[ "$color_scheme" = "'prefer-dark'" ]] && return 0
        return 1
    fi
}

# Only change if not in KDE
if [[ "$XDG_SESSION_DESKTOP" != "KDE" ]]; then
    KvantumTheme="$(grep 'theme=' ~/.config/Kvantum/kvantum.kvconfig)"

    # Dark theme configuration
    if is_dark_theme && [ "$KvantumTheme" != "theme=BigAdwaitaRoundDark" ]; then
        # Configure GTK4 dark theme
        if [[ "$XDG_CURRENT_DESKTOP" = *"Cinnamon" ]] || [[ "$XDG_CURRENT_DESKTOP" == "XFCE" ]] || [[ "$XDG_SESSION_DESKTOP" == "xfce" ]]; then
            dconf write /org/gnome/desktop/interface/color-scheme "'prefer-dark'"
        fi
        
        # Get icon theme based on desktop environment
        if [[ "$XDG_CURRENT_DESKTOP" == "XFCE" ]] || [[ "$XDG_SESSION_DESKTOP" == "xfce" ]]; then
            IconTheme="$(xfconf-query -c xsettings -p /Net/IconThemeName 2>/dev/null)"
        else
            IconTheme="$(dconf read /org/gnome/desktop/interface/icon-theme)"
        fi
        
        mkdir -p ~/.config/Kvantum/
        echo '[General]
    theme=BigAdwaitaRoundGtkDark' > ~/.config/Kvantum/kvantum.kvconfig

        # Copy the configuration file for the dark theme
        cp -f /usr/share/sync-kde-and-gtk-places/biglinux-dark ~/.config/kdeglobals

        # Process and set dark icon theme
        IconFolder="$(ls -d /usr/share/icons/*/ ~/.local/share/icons/*/ 2> /dev/null | grep -i dark | grep -im1 "/${IconTheme//\'/}")"
        IconFolderClean1=${IconFolder%/}
        IconFolderClean2=${IconFolderClean1##*/}
        if [ "$IconFolderClean2" != "" ]; then
            if [[ "$XDG_CURRENT_DESKTOP" = *"Cinnamon" ]]; then
                dconf write /org/cinnamon/desktop/interface/icon-theme "'$IconFolderClean2'"
            elif [[ "$XDG_CURRENT_DESKTOP" == "XFCE" ]] || [[ "$XDG_SESSION_DESKTOP" == "xfce" ]]; then
                xfconf-query -c xsettings -p /Net/IconThemeName -s "$IconFolderClean2"
            else
                [ -n "$(dconf read /org/gnome/desktop/interface/color-scheme)" ] && dconf write /org/gnome/desktop/interface/icon-theme "'$IconFolderClean2'"
            fi
        fi

        exit 0
    fi

    # Light theme configuration
    if ! is_dark_theme && [ "$KvantumTheme" != "theme=BigAdwaitaRound" ]; then
        # Configure GTK4 light theme
        if [[ "$XDG_CURRENT_DESKTOP" = *"Cinnamon" ]] || [[ "$XDG_CURRENT_DESKTOP" == "XFCE" ]] || [[ "$XDG_SESSION_DESKTOP" == "xfce" ]]; then
            dconf write /org/gnome/desktop/interface/color-scheme "'default'"
        fi
        
        # Get icon theme based on desktop environment
        if [[ "$XDG_CURRENT_DESKTOP" == "XFCE" ]] || [[ "$XDG_SESSION_DESKTOP" == "xfce" ]]; then
            IconTheme="$(xfconf-query -c xsettings -p /Net/IconThemeName 2>/dev/null)"
        else
            IconTheme="$(dconf read /org/gnome/desktop/interface/icon-theme)"
        fi
        
        mkdir -p ~/.config/Kvantum/
        echo '[General]
    theme=BigAdwaitaRoundGtk' > ~/.config/Kvantum/kvantum.kvconfig

        # Copy the configuration file for the light theme
        cp -f /usr/share/sync-kde-and-gtk-places/biglinux ~/.config/kdeglobals

        # Process and set light icon theme
        IconThemeWithoutDark="$(echo $IconTheme | sed 's|-dark||gi;s|dark||gi')"
        IconFolder="$(ls -d /usr/share/icons/*/ ~/.local/share/icons/*/ 2> /dev/null | grep -vi dark | grep -im1 "/${IconThemeWithoutDark//\'/}")"
        IconFolderClean1=${IconFolder%/}
        IconFolderClean2=${IconFolderClean1##*/}
        if [ "$IconFolderClean2" != "" ]; then
            if [[ "$XDG_CURRENT_DESKTOP" = *"Cinnamon" ]]; then
                dconf write /org/cinnamon/desktop/interface/icon-theme "'$IconFolderClean2'"
            elif [[ "$XDG_CURRENT_DESKTOP" == "XFCE" ]] || [[ "$XDG_SESSION_DESKTOP" == "xfce" ]]; then
                xfconf-query -c xsettings -p /Net/IconThemeName -s "$IconFolderClean2"
            else
                [ -n "$(dconf read /org/gnome/desktop/interface/color-scheme)" ] && dconf write /org/gnome/desktop/interface/icon-theme "'$IconFolderClean2'"
            fi
        fi

        exit 0
    fi
fi
