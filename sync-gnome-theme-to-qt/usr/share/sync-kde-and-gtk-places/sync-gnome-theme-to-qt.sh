#!/bin/bash

is_xfce() {
    [[ "${XDG_CURRENT_DESKTOP:-}" == "XFCE" ]] || [[ "${XDG_SESSION_DESKTOP:-}" == "xfce" ]]
}

is_cinnamon() {
    [[ "${XDG_CURRENT_DESKTOP:-}" == *"Cinnamon"* ]] || \
        [[ "${XDG_SESSION_DESKTOP:-}" == "cinnamon" ]] || \
        [[ "${DESKTOP_SESSION:-}" == "cinnamon" ]]
}

find_icon_theme() {
    local theme="$1"
    local dir name

    [[ -n "$theme" ]] || return 1

    for dir in "$HOME/.local/share/icons/$theme" "/usr/share/icons/$theme"; do
        if [[ -d "$dir" ]]; then
            printf '%s\n' "$theme"
            return 0
        fi
    done

    for dir in "$HOME"/.local/share/icons/* /usr/share/icons/*; do
        [[ -d "$dir" ]] || continue
        name="${dir##*/}"
        if [[ "${name,,}" == "${theme,,}" ]]; then
            printf '%s\n' "$name"
            return 0
        fi
    done

    return 1
}

sync_xfce_icon_theme() {
    local mode="$1"
    local current base target

    is_xfce || return 0

    current="$(xfconf-query -c xsettings -p /Net/IconThemeName 2>/dev/null || true)"
    [[ -n "$current" ]] || return 0

    base="$(printf '%s' "$current" | sed -E 's/[-_ ]?(dark|light)$//I')"

    if [[ "$mode" == "dark" ]]; then
        target="$(find_icon_theme "${base}-dark" || true)"
    else
        target="$(find_icon_theme "${base}-light" || true)"
        [[ -n "$target" ]] || target="$(find_icon_theme "$base" || true)"
    fi

    [[ -n "$target" ]] || return 0
    [[ "$target" == "$current" ]] && return 0

    xfconf-query -c xsettings -p /Net/IconThemeName -s "$target" 2>/dev/null || true
}

normalize_cinnamon_icon_theme() {
    local mode="$1"
    local current="$2"
    local base target

    base="$(printf '%s' "$current" | sed -E 's/[-_ ]?(dark|light)$//I')"

    if [[ "$mode" == "dark" ]]; then
        target="$(find_icon_theme "${base:-bigicons-papient}-dark" || true)"
        [[ -n "$target" ]] || target="${current:-bigicons-papient-dark}"
    else
        target="$(find_icon_theme "${base:-bigicons-papient}" || true)"
        [[ -n "$target" ]] || target="bigicons-papient"
    fi

    printf '%s\n' "$target"
}

sync_xfce_window_theme() {
    local theme="$1"
    local sync_themes

    is_xfce || return 0
    [[ -n "$theme" ]] || return 0

    sync_themes="$(xfconf-query -c xsettings -p /Xfce/SyncThemes 2>/dev/null || true)"
    [[ "$sync_themes" == "true" || "$sync_themes" == "1" ]] || return 0

    if [[ -d "$HOME/.themes/$theme/xfwm4" || -d "/usr/share/themes/$theme/xfwm4" ]]; then
        xfconf-query -c xfwm4 -p /general/theme -s "$theme" 2>/dev/null || true
    fi
}

sync_xfce_panel_theme() {
    local mode="$1"
    local dark_mode="false"
    local state_dir state_file previous_mode

    is_xfce || return 0

    if [[ "$mode" == "dark" ]]; then
        dark_mode="true"
    fi

    xfconf-query -c xfce4-panel -p /panels/dark-mode -n -t bool -s "$dark_mode" 2>/dev/null || true

    state_dir="${XDG_RUNTIME_DIR:-/tmp}"
    state_file="$state_dir/sync-gnome-theme-to-qt-xfce-panel-mode"
    previous_mode="$(cat "$state_file" 2>/dev/null || true)"
    printf '%s\n' "$mode" > "$state_file" 2>/dev/null || true

    [[ -n "$previous_mode" ]] || return 0
    [[ "$previous_mode" != "$mode" ]] || return 0
    pgrep -x xfce4-panel >/dev/null 2>&1 || return 0

    xfce4-panel --restart >/dev/null 2>&1 || true
}

set_ini_key() {
    local file="$1"
    local key="$2"
    local value="$3"

    mkdir -p "$(dirname "$file")"
    touch "$file"

    if ! grep -q '^\[Settings\]' "$file"; then
        printf '[Settings]\n' | cat - "$file" > "$file.tmp"
        mv -f "$file.tmp" "$file"
    fi

    if grep -q "^${key}=" "$file"; then
        sed -i "s|^${key}=.*|${key}=${value}|" "$file"
    else
        sed -i "/^\\[Settings\\]/a ${key}=${value}" "$file"
    fi
}

remove_ini_key() {
    local file="$1"
    local key="$2"

    [[ -f "$file" ]] || return 0
    sed -i "/^${key}=/d" "$file"
}

read_dconf_string() {
    local key="$1"
    dconf read "$key" 2>/dev/null | sed "s/^'//;s/'$//" || true
}

sync_adw_color_scheme() {
    local color_scheme="$1"

    export ADW_DEBUG_COLOR_SCHEME="$color_scheme"
    dbus-update-activation-environment --systemd ADW_DEBUG_COLOR_SCHEME 2>/dev/null || true
    systemctl --user import-environment ADW_DEBUG_COLOR_SCHEME 2>/dev/null || true
}

sync_gtk_color_scheme() {
    local mode="$1"
    local gtk_theme icon_theme prefer_dark color_scheme

    if [[ "$mode" == "dark" ]]; then
        prefer_dark="true"
        color_scheme="prefer-dark"
    else
        prefer_dark="false"
        color_scheme="default"
    fi

    if is_xfce; then
        sync_xfce_icon_theme "$mode"
        gtk_theme="$(xfconf-query -c xsettings -p /Net/ThemeName 2>/dev/null || true)"
        icon_theme="$(xfconf-query -c xsettings -p /Net/IconThemeName 2>/dev/null || true)"
        sync_xfce_window_theme "$gtk_theme"
        sync_xfce_panel_theme "$mode"
    elif is_cinnamon; then
        gtk_theme="$(read_dconf_string /org/cinnamon/desktop/interface/gtk-theme)"
        icon_theme="$(read_dconf_string /org/cinnamon/desktop/interface/icon-theme)"
        icon_theme="$(normalize_cinnamon_icon_theme "$mode" "$icon_theme")"
    else
        gtk_theme="$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null | sed "s/^'//;s/'$//" || true)"
        icon_theme="$(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null | sed "s/^'//;s/'$//" || true)"
    fi

    if [[ "$mode" == "dark" ]]; then
        [[ -n "$gtk_theme" ]] || gtk_theme="adw-gtk3-dark"
        [[ -n "$icon_theme" ]] || icon_theme="bigicons-papient-dark"
    else
        [[ -n "$gtk_theme" ]] || gtk_theme="adw-gtk3"
        [[ -n "$icon_theme" ]] || icon_theme="bigicons-papient"
    fi

    for gtk_dir in "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"; do
        set_ini_key "$gtk_dir/settings.ini" "gtk-theme-name" "$gtk_theme"
        set_ini_key "$gtk_dir/settings.ini" "gtk-icon-theme-name" "$icon_theme"
        if is_xfce; then
            remove_ini_key "$gtk_dir/settings.ini" "gtk-application-prefer-dark-theme"
        else
            set_ini_key "$gtk_dir/settings.ini" "gtk-application-prefer-dark-theme" "$prefer_dark"
        fi
    done

    if is_cinnamon; then
        gsettings set org.cinnamon.desktop.interface gtk-theme "$gtk_theme" 2>/dev/null || true
        gsettings set org.cinnamon.desktop.interface icon-theme "$icon_theme" 2>/dev/null || true
    fi

    gsettings set org.gnome.desktop.interface gtk-theme "$gtk_theme" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface icon-theme "$icon_theme" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface color-scheme "$color_scheme" 2>/dev/null || true
    if is_cinnamon; then
        sync_adw_color_scheme "$color_scheme"
    fi
}

# Function to check if current theme is dark
is_dark_theme() {
    if [[ "$XDG_CURRENT_DESKTOP" = *"Cinnamon" ]]; then
        local current_theme
        current_theme=$(dconf read /org/cinnamon/desktop/interface/gtk-theme)
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
    elif is_xfce; then
        # XFCE theme check
        local current_theme
        current_theme=$(xfconf-query -c xsettings -p /Net/ThemeName 2>/dev/null)
        [[ "$current_theme" == *dark* ]] || [[ "$current_theme" == *Dark* ]] && return 0
        return 1
    else
        # GNOME color scheme check
        local color_scheme
        color_scheme=$(dconf read /org/gnome/desktop/interface/color-scheme)
        [[ "$color_scheme" = "'prefer-dark'" ]] && return 0
        return 1
    fi
}

# Only change if not in KDE
if [[ "${XDG_SESSION_DESKTOP:-}" != "KDE" ]]; then
    KvantumTheme="$(grep '^[[:space:]]*theme=' ~/.config/Kvantum/kvantum.kvconfig 2>/dev/null | sed 's/^[[:space:]]*//' || true)"

    # Dark theme configuration
    if is_dark_theme; then
        sync_gtk_color_scheme dark
        mkdir -p ~/.config/Kvantum/
        if [ "$KvantumTheme" != "theme=BigAdwaitaRoundGtkDark" ]; then
            echo '[General]
    theme=BigAdwaitaRoundGtkDark' > ~/.config/Kvantum/kvantum.kvconfig

            # Copy the configuration file for the dark theme
            cp -f /usr/share/sync-kde-and-gtk-places/biglinux-dark ~/.config/kdeglobals
        fi

        exit 0
    fi

    # Light theme configuration
    if ! is_dark_theme; then
        sync_gtk_color_scheme light
        mkdir -p ~/.config/Kvantum/
        if [ "$KvantumTheme" != "theme=BigAdwaitaRoundGtk" ]; then
            echo '[General]
    theme=BigAdwaitaRoundGtk' > ~/.config/Kvantum/kvantum.kvconfig

            # Copy the configuration file for the light theme
            cp -f /usr/share/sync-kde-and-gtk-places/biglinux ~/.config/kdeglobals
        fi

        exit 0
    fi
fi
