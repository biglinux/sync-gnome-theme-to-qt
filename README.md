# sync-gnome-theme-to-qt

Systemd service that monitors when the user switches between normal and dark Gnome themes, also changing Kvantum's configuration so that QT programs follow the same theme.

GNOME interface settings are source-only: the service propagates them to GTK
configuration files and Qt. XFCE and Cinnamon keep their desktop-specific
normalization and mirror the resulting state to GNOME settings.
