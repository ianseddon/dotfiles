# The engine is the rootless user daemon from docker.service, not /var/run/docker.sock.
# Tailscale SSH sessions lack XDG_RUNTIME_DIR, so use the user manager's fixed path.
if not set -q DOCKER_HOST
    set -gx DOCKER_HOST "unix:///run/user/"(id -u)"/docker.sock"
end
