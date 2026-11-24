# Dev servers on the tailnet (README: "Dev servers over Tailscale").
# portless shares every app it runs through `tailscale serve`, beside its
# https://*.localhost URL, so the headless host's apps open from other devices.
set -gx PORTLESS_TAILSCALE 1
# The local Keycloak (workforce-monorepo compose.yml) is published at this URL
# and issues tokens for it, so its sign-in pages load from other devices too.
set -gx KC_HOSTNAME https://m75q.hawk-monster.ts.net:8080
