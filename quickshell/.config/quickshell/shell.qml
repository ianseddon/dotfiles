import QtQuick
import Quickshell
import "theme"

// The desktop shell. Design: docs/desktop-shell/ in the dotfiles repo.
ShellRoot {
    LazyLoader {
        active: Theme.previewOpen

        ThemePreview {}
    }
}
