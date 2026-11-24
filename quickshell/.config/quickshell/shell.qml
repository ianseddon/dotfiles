import QtQuick
import Quickshell
import "theme"
import "bar"

// The desktop shell. Design: docs/desktop-shell/ in the dotfiles repo.
ShellRoot {
    Variants {
        model: Quickshell.screens

        Bar {}
    }

    LazyLoader {
        active: Theme.previewOpen

        ThemePreview {}
    }
}
