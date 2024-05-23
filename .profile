if [ -n "$DESKTOP_SESSION" ]; then
	eval "$(gnome-keyring-daemon --start)"
	export SSH_AUTH_SOCK="$XDG_USER_RUNTIME_DIR/gcr/ssh"
fi

. "$HOME/.rye/env"
