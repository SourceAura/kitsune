import Quickshell
import QtQuick

FloatingWindow {
    width: 1120
    height: 940
    visible: true
    color: "#07070d"
    title: "kitsune-mantra"

    MantraSetup {
        anchors.fill: parent
        confPath: {
            const e = Quickshell.env("KITSUNE_THEME_CONF");
            return e && e.length > 0 ? e
                : Quickshell.env("HOME") + "/.local/share/qylock/themes/kitsune/theme.conf";
        }
        writerPath: (Quickshell.env("KITSUNE_MANTRA_DIR") || ".") + "/mantraconf.py"
    }
}
