# Secrets-management proposal

## Recommendation

Start with **SOPS + age**, using a separate encrypted file and age recipient set for each consumer or trust boundary. Stop sourcing a single secret file into every interactive Fish process. Decrypt or fetch only for the target command, and run agents and untrusted dependency code in containers or VMs that cannot inspect the host filesystem, process table, or decryption identity.

The product conclusions are deliberately distinct:

- **Recommended architecture now:** SOPS + age. It fits one operator and static API tokens, works offline, has no always-on service, and can scope each sandbox to one ciphertext file and recipient.
- **Best single product:** Infisical OSS. It combines a UI, projects, machine identities, Universal Auth, and command-scoped injection, but adds a three-container service and permanent bootstrap secrets.
- **Capability-maximizing product:** OpenBao. Choose it when free-form policy, authoritative access audit, PKI, or leased database credentials justify materially greater operational burden.

The current design loads `secrets.fish` unconditionally from [`config.fish`](../fish/.config/fish/config.fish#L1). The ignore rule in [`.gitignore`](../.gitignore#L1) reduces Git-commit risk but does not encrypt the local file, stop on-device scanners, or prevent every descendant of an exporting shell from inheriting those variables.

## Threat model and boundaries

**Decision:** encryption at rest is not protection from arbitrary code already running as the same Unix user. Once a secret is available through a process environment, plaintext file, memory, unlocked password-manager session, credential API, or decryption agent, code in that trust domain can use or exfiltrate it. A session-long unlock cache reduces prompts; it is not a security boundary.

| Boundary | What the attacker gets | What helps | What does not solve it |
|---|---|---|---|
| Encrypted storage or backup exposure | Repository, disk copy, database backup, or synced vault ciphertext without the key | Strong encryption; keeping recovery/decryption material separate; tested backups | `.gitignore`; filesystem location; redaction after plaintext is produced |
| Same-user workstation malware | The user's files, process capabilities, unlocked clients, and command execution | Do not export globally; decrypt only for one command; hardware-backed decryption with user presence; stronger OS/VM isolation | A cached passphrase, keyring, password-manager session, or local agent callable by that same user |
| One compromised sandboxed agent | Everything injected into that sandbox plus every reachable service its bootstrap identity authorizes | One file/project/policy and bootstrap identity per agent; short TTL/use limits where supported; no host filesystem/PID access; outbound policy | Splitting variable names inside a globally readable master file; redaction alone |
| Tailnet or secret-server host compromise | Reachable manager endpoints, or on-host databases, server keys, and live manager memory | Tailscale ACLs plus application authentication; host hardening; offline recovery; per-workload credentials; audit | Tailnet membership alone. ACLs control reachability, not Infisical/OpenBao authorization |

Practical controls follow directly:

1. Remove global shell exports. Launch only the consumer under a decryption/fetch wrapper.
2. Split secrets by consumer. Rotate externally issued static API keys after any suspected exposure; moving an already exposed value into ciphertext does not revoke it.
3. Treat the launcher as trusted. Isolate untrusted dependencies and agents from the host PID namespace, home directory, credential sockets, and decryption identities.
4. Give every unattended workload a different bootstrap identity. Never mount a workstation recovery identity or unrelated ciphertext into a sandbox.
5. Prefer short-lived, policy-scoped credentials when the upstream service can issue them. A manager cannot make a third-party static API key dynamic.

## Evaluation and ranking

Scores are 1 (poor) through 5 (best). The weighted total is $\sum(\text{weight}\times\text{score}/5)$. OSI status is also a gate: a non-OSI candidate cannot enter the ranked set.

| Criterion | Weight |
|---|---:|
| Fit for static API tokens and one operator | 20 |
| Least-privilege delivery to sandboxes | 20 |
| No plaintext canonical store | 15 |
| Operational footprint and recovery | 12 |
| Offline availability | 10 |
| Audit, revocation, and rotation | 8 |
| Docker/Podman Compose ergonomics | 5 |
| OSI-approved licensing | 5 |
| Hardware-backed evolution path | 5 |
| **Total** | **100** |

| Rank | Architecture | Static fit | Sandbox | Encrypted store | Operations | Offline | Audit/rotation | Compose | OSI | Hardware | Weighted total |
|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | SOPS + age | 5 | 4 | 5 | 5 | 5 | 2 | 4 | 5 | 5 | **90.2** |
| 2 | Infisical OSS | 4 | 4 | 5 | 2 | 1 | 4 | 5 | 5 | 2 | **72.2** |
| 3 | OpenBao | 3 | 5 | 5 | 1 | 1 | 5 | 3 | 5 | 3 | **70.4** |

The close second/third scores are intentional. Infisical wins current usability; OpenBao wins policy and dynamic capability. Neither beats a serverless encrypted-file design for one operator with primarily static tokens.

## Ranked architectures

### 1. Encrypted-first, no always-on service: SOPS + age

**Design**

- Keep one encrypted dotenv or YAML file per trust boundary—for example, workstation-only tools, each homelab service, and each agent—not one master file. SOPS supports dotenv/YAML and age recipients; `.sops.yaml` creation rules accept an age recipient list ([SOPS README](https://github.com/getsops/sops), [configuration source](https://github.com/getsops/sops/blob/main/config/config.go)).
- Give each file its consumer recipient plus a separately stored offline recovery recipient. Every matching recipient can decrypt the whole file, so file boundaries—not key names inside one file—are the authorization unit.
- Generate a native workstation age identity, then encrypt that identity file separately with `age -p`. Do **not** point `SOPS_AGE_KEY_FILE` at the encrypted file: SOPS parses that input directly as plaintext Bech32 identities. Configure the trusted launcher with `SOPS_AGE_KEY_CMD='age -d /path/to/encrypted-identity.age'` so SOPS executes `age`, receives the decrypted identity on standard output, and parses it ([age identity-file support](https://github.com/FiloSottile/age/blob/main/doc/age.1.ronn), [SOPS identity loader](https://github.com/getsops/sops/blob/main/age/keysource.go)). `age-plugin-batchpass` can make the command noninteractive through a passphrase environment variable or file descriptor, but that supplied passphrase becomes the secret zero and does not improve same-user isolation ([batchpass manual](https://github.com/FiloSottile/age/blob/main/doc/age-plugin-batchpass.1.ronn)).
- For an unattended homelab service, provision a service-specific native age identity on that host. For an agent, either let a trusted launcher decrypt only that agent's file or mount only the agent-specific identity and ciphertext. Never mount the workstation or recovery identity.
- Use `sops exec-env` for environment consumers and `sops exec-file` for file consumers; the current CLI implements command-scoped environment injection and file/FIFO delivery ([SOPS CLI source](https://github.com/getsops/sops/blob/main/cmd/sops/main.go)). Avoid persistent decrypted output.

**Operational footprint:** two local OSI-licensed CLIs, encrypted files in the repository or deployment bundle, one protected identity per unattended consumer, and one offline recovery identity. No database, network service, account, or unseal procedure.

**Secret zero:** the workstation identity passphrase; a service or sandbox's own age private identity when it must decrypt unattended. That static identity grants only the ciphertext files addressed to its recipient.

**Recovery:** use the offline recovery identity to decrypt, add replacement recipients, and re-encrypt. Restore ciphertext from Git/backup. If an API token may have been exposed, rotate it at the issuer before re-encrypting it.

**Offline behavior:** full decrypt/edit/launch capability remains available wherever the selected ciphertext and matching identity are local. The external API using the token may still require a network.

**Compromised agent blast radius:** agent A gets the plaintext injected into A and, if it holds an identity, every file addressed to A. It does not get agent B's file unless sandbox isolation also fails or the launcher mistakenly shares B's recipient/file. A compromised workstation user can still invoke any currently usable workstation identity.

**Pros**

- Lowest operating and recovery burden.
- Honest offline behavior and no service outage mode.
- Encrypted canonical store with reviewable, versioned ciphertext.
- Natural clean cutover from dotenv-style static keys.
- Strong hardware path: `age-plugin-yubikey` supports the PIV-capable YubiKey 5 family; the FIDO-only blue Security Key does not support PIV ([plugin README](https://github.com/str4d/age-plugin-yubikey)).

**Cons**

- No central read audit, immediate revocation, UI, or leased dynamic secrets.
- Rotation means updating and redistributing ciphertext.
- File/recipient mistakes are policy mistakes; there is no server to deny a bad read.
- Passphrase caching or a software identity remains callable by same-user malware.

### 2. Centralized and developer-friendly: Infisical OSS

**Design**

- Deploy the MIT-licensed core as a tailnet-only Docker/Podman Compose stack: Infisical, PostgreSQL, and Redis. The official Compose design uses exactly those three containers ([Compose guide](https://infisical.com/docs/self-hosting/deployment-options/docker-compose)).
- Keep Tailscale ACLs narrow, bind ingress to the intended interface/proxy, and retain Infisical authentication. Tailnet reachability is not a machine identity.
- Use the local administrator account for the sole human. Create one project per sandbox or workload, then assign one Universal Auth machine identity the built-in project `Viewer` role. Free self-hosted includes built-in roles, but custom roles are Enterprise; trusted-IP restrictions for Universal Auth are also paid ([RBAC](https://infisical.com/docs/documentation/platform/access-controls/role-based-access-controls), [Universal Auth](https://infisical.com/docs/documentation/platform/identities/universal-auth)).
- Launch local tools with `infisical run -- command`, which injects fetched secrets only into the child application process ([CLI documentation](https://infisical.com/docs/cli/commands/run)). Use the same identity/project separation for Compose entrypoints or trusted launchers.
- Protect and back up the permanent server bootstrap configuration separately. A minimal self-hosted instance requires `ENCRYPTION_KEY`, `AUTH_SECRET`, `DB_CONNECTION_URI`, and `REDIS_URL`; losing the encryption key can make the database unusable ([environment reference](https://infisical.com/docs/self-hosting/configuration/envars)).

Do not design the free baseline around custom roles, trusted-IP restrictions, Dynamic Secrets, or audit-log streaming. Current documentation places those features behind paid/Enterprise licensing. Separate projects plus `Viewer` are the coarse free-core policy.

**Operational footprint:** three always-on containers, TLS/tailnet ingress, PostgreSQL backups, Redis, upgrade monitoring, local human account recovery, machine identities, and protected bootstrap configuration.

**Secret zero:** each workload's Universal Auth client ID/client secret (or derived access token); the server's encryption/auth keys and database/Redis credentials. Periodic tokens can reduce repeated client-secret use, but the first credential still must be provisioned ([Universal Auth](https://infisical.com/docs/documentation/platform/identities/universal-auth)).

**Recovery:** restore PostgreSQL plus the exact encryption/bootstrap configuration; Redis cache/job data is reconstructible according to the Compose storage model. Keep an offline copy of server bootstrap values and administrator recovery material, then reissue workload client secrets if their copies are lost or exposed.

**Offline behavior:** a running child keeps its already injected environment, but a new launch or refresh cannot fetch while Infisical, PostgreSQL, Redis, or the tailnet path is unavailable.

**Compromised agent blast radius:** agent A can read every secret in A's project through its `Viewer` identity, not B's separate project. A stolen long-lived client secret keeps that authority until expiry or revocation. Compromise of the Infisical host and its bootstrap keys threatens the full store.

**Pros**

- Best integrated product UX for this use: UI, projects, machine identities, short-lived access tokens, and CLI injection.
- Central updates and identity revocation without redistributing every ciphertext.
- Straightforward Docker/Podman Compose fit.
- MIT core satisfies the OSI requirement when `ee/` features are excluded.

**Cons**

- Three-container availability and backup burden for one person.
- No fresh fetch during a manager or tailnet outage.
- Permanent server and workload bootstrap secrets remain.
- Free-core policy is project-wide and read-only, not arbitrary path/action policy; several attractive controls are paid.
- Injected plaintext remains exposed to the receiving process and same-user trust domain.

### 3. Centralized policy and dynamic-secret engine: OpenBao

**Design**

- Run one MPL-2.0 OpenBao node on the tailnet with Integrated Storage/Raft. A single node is not highly available, but avoids introducing an external database for this scale ([Raft storage](https://openbao.org/docs/configuration/storage/raft/)).
- Initialize with Shamir sealing and store the unseal shares as offline recovery material. OpenBao starts sealed and cannot authenticate or serve secrets until unsealed ([seal model](https://openbao.org/docs/concepts/seal/)).
- Mount KV v2 for current static API keys. Create a separate path policy and AppRole for every workload; do not share RoleIDs/SecretIDs across agents.
- For one-shot sandboxes, issue short-TTL, limited-use SecretIDs and tokens. AppRole supports TTL and use-count controls ([AppRole](https://openbao.org/docs/auth/approle/)).
- For long-running OpenBao Agent auto-auth/templates, issue a renewable, policy-scoped token with unlimited uses. Auto-auth explicitly does not support limited-use tokens because it does not track remaining uses; AppRole `token_num_uses` must be `0` ([Agent auto-auth](https://openbao.org/docs/agent-and-proxy/autoauth/)).
- Enable at least two durable audit devices if authoritative access history matters. OpenBao records API requests/responses and services a request only if at least one enabled audit device can record it; if all are blocked, requests stop. That guarantee adds write latency, storage, and another availability dependency ([audit devices](https://openbao.org/docs/audit/)).

**Operational footprint:** OpenBao server, TLS/tailnet ingress, initialization/unseal procedure, policy and AppRole lifecycle, audit sinks, Raft snapshots, upgrades, and monitoring. PKI/database engines add their own privileged connections and rotation operations.

**Secret zero:** each workload's RoleID and SecretID; operator unseal shares and an administrator token/auth method. Short TTL/use limits reduce replay but cannot remove initial provisioning.

**Recovery:** save and test Raft snapshots; restore a snapshot and unseal with the protected Shamir shares. OpenBao provides explicit `bao operator raft snapshot save` and `restore` commands ([Raft operator commands](https://openbao.org/docs/commands/operator/raft/)).

**Offline behavior:** a process keeps material already rendered or injected, but no new login/read/lease is available while the node is down, sealed, or unreachable.

**Compromised agent blast radius:** agent A can exercise A's path policy until its SecretID/token expires, is consumed, or is revoked. It cannot read B's path. Any plaintext already returned to A is lost. Compromise of the unsealed server host threatens all mounted secrets and issuance engines.

**Pros**

- Strongest unrestricted OSS policy model in the ranked set.
- Auditable access with fail-closed behavior when every audit sink is unavailable.
- Leased database credentials, PKI, revocation, and mature token controls.
- Precise per-path blast radius.

**Cons**

- Highest setup, policy, recovery, and availability burden.
- Manual unseal and single-node outage friction.
- Easy to build an elaborate control plane around static keys that the upstream provider cannot rotate dynamically.
- Agent auto-auth cannot use limited-use tokens.
- Retrieved plaintext still crosses into the workload trust domain.

## Product conclusions

**SOPS + age is the recommended architecture to start with. Infisical OSS is the best single product for the stated balance. OpenBao is the capability-maximizing product when central policy, authoritative audit, PKI, or dynamic credentials justify its burden.**

## Staged migration

This is a clean cutover plan, not a compatibility layer. Do not execute it until implementation is a separate approved task.

### Stage 1: inventory and establish recovery

1. Inventory secret **names**, issuers, consumers, and rotation procedures without copying values into another plaintext document.
2. Generate a native workstation age identity and separate offline recovery identity. Encrypt the workstation identity file with `age -p`, then configure the launcher to expose its plaintext to SOPS only through `SOPS_AGE_KEY_CMD='age -d /path/to/encrypted-identity.age'`; `SOPS_AGE_KEY_FILE` must not reference the encrypted file.
3. Define `.sops.yaml` creation rules and one encrypted file per consumer. Address each file to its consumer plus the recovery recipient.
4. Prove recovery on disposable test data: decrypt with the normal identity, then separately with the offline recovery identity.

### Stage 2: replace global workstation injection

1. Add explicit launchers for each trusted local command using only its encrypted file.
2. Verify a command launched outside a wrapper receives none of those variables and a wrapped command receives only its declared set.
3. Remove the unconditional `source ~/.config/fish/secrets.fish` line. Do not replace it with a startup-time decrypt or globally exported cache; that recreates the same trust domain.
4. Confirm the parent Fish process and a newly launched unrelated child do not contain the old variable names.

### Stage 3: isolate homelab services and agents

1. Provision one age identity and encrypted file per unattended Compose workload, or let a trusted launcher decrypt the selected file into that workload only.
2. Give each agent its own file/recipient. Mount neither the workstation identity, offline recovery identity, home directory, host process namespace, nor other agents' ciphertext.
3. Prefer file delivery for software that supports credential files. Environment delivery is acceptable when it is the application's only interface, but the complete child process tree can use it.
4. Test agent A and agent B independently; A must fail to decrypt or receive B's material.

### Stage 4: rotate and remove plaintext

1. After every new launch path works, rotate externally issued API keys that existed in `secrets.fish` or may have entered logs/process environments.
2. Write only the replacements into their consumer-specific encrypted stores.
3. Delete the plaintext copies and any temporary migration output.
4. Start a fresh login shell and verify the old variables are absent from both the shell and unrelated children.

## Decision rules

- **Remain on SOPS + age** while secrets are mostly static, one operator owns them, file distribution is manageable, and offline launch matters.
- **Choose Infisical OSS** when multiple always-on consumers make ciphertext distribution/rotation painful, or central update, identity revocation, and a UI become worth a three-container service. Use separate projects and built-in roles; do not assume paid controls.
- **Choose OpenBao instead** when unrestricted path/action policies, fail-closed audit, PKI, or leased database credentials are actual requirements. Do not deploy Infisical and OpenBao together; two central managers double secret-zero, backup, policy, and outage surfaces.
- **Add `systemd-creds` as a delivery complement** for a specific systemd service when host/TPM-bound activation and a private credential directory help. It does not replace the cross-host source of truth.

Buy a **PIV-capable YubiKey 5** only after the SOPS workflow proves useful, unless meaningful resistance to silent same-user decryption is required immediately. In that case, use hardware-backed decryption with a touch/user-presence policy from the start. A FIDO2-only Security Key is not a substitute for `age-plugin-yubikey`; retain the passphrase-encrypted identity if compatible PIV hardware is unavailable. Hardware approval protects key use before decryption, not plaintext after an approved command receives it.

## Future agent hardening: Infisical Agent Vault

Revisit Agent Vault only when agents must be unable to possess raw credentials and accepting preview/API instability is an explicit decision. Its separate-host HTTP/HTTPS MITM proxy injects credentials after the agent sends a request, so the sandbox receives a proxy token and custom CA rather than the upstream key. Configure service/path egress rules, `unmatched_host_policy=deny`, short-lived vault-scoped agent tokens, and network isolation around the injection proxy ([upstream README](https://github.com/Infisical/agent-vault)).

This is a different control from SOPS/Infisical/OpenBao injection: a compromised agent can still spend its authorized capability, but cannot print a raw key it never receives. It is future-only because upstream marks the project **Preview**, active development, and API-subject-to-change. Do not put it in the baseline and do not treat output redaction as equivalent credential non-possession.

## Candidate comparison

### Storage, identity, delivery, and availability

| Candidate | Canonical storage | Human unlock / administration | Workload identity and scope | Delivery | Offline and server dependency |
|---|---|---|---|---|---|
| **SOPS + age** | SOPS encrypts YAML, JSON, dotenv, INI, or binary files and wraps their data keys to one or more age recipients ([SOPS README](https://github.com/getsops/sops), [age manual](https://github.com/FiloSottile/age/blob/main/doc/age.1.ronn)). | `age -p` can protect an identity file interactively. SOPS does not decrypt that file through `SOPS_AGE_KEY_FILE`; its launcher must use `SOPS_AGE_KEY_CMD` to run `age -d` and return the plaintext identity ([age manual](https://github.com/FiloSottile/age/blob/main/doc/age.1.ronn), [SOPS identity loader](https://github.com/getsops/sops/blob/main/age/keysource.go)). | No online workload-auth service. Scope is expressed structurally by separate ciphertext files and recipient sets; possession of a matching identity is the authority. | `sops exec-env` injects decrypted values into a command environment; `--pristine` avoids forwarding the existing environment. `sops exec-file` exposes decrypted content through a FIFO by default; `--no-fifo` selects a regular temporary file ([current command source](https://github.com/getsops/sops/blob/main/cmd/sops/main.go#L186-L372)). | Fully local/offline when ciphertext and an identity are present; no server is required ([SOPS README](https://github.com/getsops/sops)). |
| **Infisical OSS core** | The Compose deployment stores encrypted secrets, users, projects, and configuration in PostgreSQL and uses Redis for caching/jobs ([Compose guide](https://infisical.com/docs/self-hosting/deployment-options/docker-compose)). | Local signup is supported; the first user to sign up becomes instance administrator ([Compose guide](https://infisical.com/docs/self-hosting/deployment-options/docker-compose)). | Machine identities receive roles. Universal Auth exchanges a client ID and client secret for a short-lived access token; project identities are confined to their project ([machine identities](https://infisical.com/docs/documentation/platform/identities/machine-identities), [Universal Auth](https://infisical.com/docs/documentation/platform/identities/universal-auth)). | `infisical run -- command` injects fetched secrets into the child process environment ([CLI reference](https://infisical.com/docs/cli/commands/run)). | Fresh reads require the Infisical API plus PostgreSQL and Redis; the documented Compose footprint is three containers, so this is not an offline-fetch design ([Compose guide](https://infisical.com/docs/self-hosting/deployment-options/docker-compose)). |
| **OpenBao** | Encrypted server storage; Integrated Storage persists data with Raft ([Raft storage](https://openbao.org/docs/configuration/storage/raft/), [seal model](https://openbao.org/docs/concepts/seal/)). | Operators must unseal a newly started Shamir-sealed server, then humans authenticate with a configured method/token ([seal model](https://openbao.org/docs/concepts/seal/)). | AppRole binds machine-oriented RoleIDs/SecretIDs to token policies, with TTL and use-count controls ([AppRole](https://openbao.org/docs/auth/approle/)). | API/CLI reads, or OpenBao Agent templates/auto-auth for local files or processes ([Agent auto-auth](https://openbao.org/docs/agent-and-proxy/autoauth/)). | Requires a reachable, unsealed OpenBao service for a fresh read; no fresh offline fetch ([seal model](https://openbao.org/docs/concepts/seal/)). |
| **pass** | One GPG-encrypted file per entry, optionally versioned/synchronized with Git ([official site](https://www.passwordstore.org/)). | GPG private key and its configured passphrase/agent. | Recipient selection and directory layout can divide stores, but pass has no first-class workload identity, expiring workload token, or server-side policy endpoint in its documented model. | CLI output or clipboard; application wrappers must perform any environment/file injection themselves ([official site](https://www.passwordstore.org/)). | Local and offline; Git is optional synchronization, not a required service ([official site](https://www.passwordstore.org/)). |
| **gopass** | Local GPG-encrypted password stores with Git synchronization/history ([official site](https://www.gopass.pw/), [upstream README](https://github.com/gopasspw/gopass)). | GPG private key and its configured passphrase/agent. | Multiple stores/recipients support human/team sharing, but the documented product has no first-class short-lived workload identity or policy token. | CLI output, clipboard, and add-ons; workload injection is wrapper/add-on logic ([official site](https://www.gopass.pw/)). | Explicitly supports fully offline/air-gapped use; remote Git is optional ([upstream README](https://github.com/gopasspw/gopass)). |
| **KeePassXC** | An offline encrypted KeePass database file ([getting-started guide](https://keepassxc.org/docs/KeePassXC_GettingStarted)). | Database password and optionally a key file or supported YubiKey challenge-response slot ([CLI manual](https://github.com/keepassxreboot/keepassxc/blob/develop/docs/man/keepassxc-cli.1.adoc)). | Groups/entries organize human secrets, but no first-class workload identity, scoped workload token, or server-side authorization is documented. Automation reuses database unlock factors. | GUI/browser integration, clipboard, or `keepassxc-cli show`; no native command-scoped environment injector ([CLI manual](https://github.com/keepassxreboot/keepassxc/blob/develop/docs/man/keepassxc-cli.1.adoc)). | Local/offline; file synchronization is external to KeePassXC ([getting-started guide](https://keepassxc.org/docs/KeePassXC_GettingStarted)). |
| **Vaultwarden** | A self-hosted alternative implementation of the Bitwarden Client API, backed by its server database and consumed by Bitwarden clients ([upstream README](https://github.com/dani-garcia/vaultwarden)). | Bitwarden account/master-password client flow; server administration is separate. | Users, organizations, collections, roles, and personal API keys are implemented, but Vaultwarden's upstream scope is a password-vault server, not Bitwarden Secrets Manager machine accounts ([implemented features](https://github.com/dani-garcia/vaultwarden#features)). | Bitwarden clients/CLI retrieve or copy vault entries; application injection requires a wrapper. | Server is required for fresh synchronization; an already-synced client may retain its encrypted local vault, but that is not a workload secret service ([upstream README](https://github.com/dani-garcia/vaultwarden)). |
| **Varlock** | A `.env.schema` plus environment sources. Plugins can resolve values from external backends such as 1Password, Infisical, cloud stores, or HCP Vault ([upstream README](https://github.com/dmno-dev/varlock)). | No independent vault unlock; the selected backend/source owns authentication. | Schema rules mark/validate sensitive values, but workload scope is inherited from the backend credentials and inputs. | Loads/injects environment configuration and offers runtime leak prevention/log redaction integrations ([upstream README](https://github.com/dmno-dev/varlock)). | Local schema/env use is offline; plugin-backed use inherits the backend's availability. Varlock is not itself an encrypted canonical secret backend ([plugins](https://varlock.dev/plugins/overview/)). |
| **dotenvx** | Encrypted values remain in `.env`; the decryption key is written to `.env.keys` by default or supplied separately ([encryption guide](https://dotenvx.com/docs/quickstart/encryption/)). | Possession of the private key; optional `lock`, native keychain, and managed Armor paths are documented ([encryption guide](https://dotenvx.com/docs/quickstart/encryption/)). | Key/file separation can scope deployments, but there is no first-class workload identity or server-side policy in the local encrypted-dotenv design. | `dotenvx run -- command` decrypts and injects values into the process environment at runtime ([encryption guide](https://dotenvx.com/docs/quickstart/encryption/)). | Offline with the encrypted file and private key. No server is required for the local-key path; managed key options change that dependency. |
| **systemd credentials** | Credentials may be plaintext or encrypted/authenticated blobs; encrypted credentials can be bound to a TPM2, a host key, or both ([credentials specification](https://systemd.io/CREDENTIALS/)). | Provisioned by the system administrator; the service manager decrypts at activation rather than prompting a human service by service. | Scope is a specific unit's private credential directory. This is strong per-service delivery, not a cross-host identity or secret inventory ([credentials specification](https://systemd.io/CREDENTIALS/)). | `LoadCredential=` / `LoadCredentialEncrypted=` place files in `$CREDENTIALS_DIRECTORY`; unlike environment variables, credential data is not automatically propagated down the process tree ([credentials specification](https://systemd.io/CREDENTIALS/)). | Host-local/offline when blob and binding key/TPM are available; no central server. |
| **CyberArk Conjur OSS** | Encrypted keys/secrets in PostgreSQL; startup requires the separately protected `CONJUR_DATA_KEY` ([upstream architecture](https://github.com/cyberark/conjur#architecture)). | Human and machine roles authenticate through enabled authenticators/API keys and receive signed access tokens ([upstream README](https://github.com/cyberark/conjur)). | MAML policy defines roles, privileges, resources, and authenticators for human and machine identities ([upstream README](https://github.com/cyberark/conjur#conjur)). | REST API and ecosystem integrations retrieve stored values; injection depends on the integration/launcher ([upstream README](https://github.com/cyberark/conjur)). | Requires Conjur and PostgreSQL for fresh reads; not an offline-fetch design ([upstream architecture](https://github.com/cyberark/conjur#architecture)). |
| **HashiCorp Vault Community** | Encrypted server storage with Integrated Storage/Consul and static or dynamic secret engines ([current edition matrix](https://developer.hashicorp.com/vault/tutorials/get-started/available-editions)). | Unseal plus a configured human authentication method/token. | Rich auth methods and path policies; workload identity depends on the chosen auth method. | API/CLI/Agent reads, templates, or injected files/environment according to the client integration. | Requires a reachable, unsealed Vault server for fresh reads. |
| **Bitwarden Secrets Manager** | Server-backed secrets grouped into projects ([FAQ](https://bitwarden.com/help/secrets-manager-faqs/)). | Human administration through the Bitwarden web app; self-hosting requires a Secrets Manager-enabled organization license ([FAQ](https://bitwarden.com/help/secrets-manager-faqs/)). | Machine accounts receive access to selected projects/secrets and authenticate the CLI with access tokens ([CLI reference](https://bitwarden.com/help/secrets-manager-cli/)). | `bws run` injects accessible secrets as environment variables; the official docs explicitly warn that it is not a sandbox and that untrusted commands gain the secrets ([CLI reference](https://bitwarden.com/help/secrets-manager-cli/#run)). | Fresh reads require the Bitwarden service; self-hosting does not make fetches offline. |
| **Infisical Agent Vault** | Encrypted local SQLite by default; PostgreSQL is available for production/multiple instances, and an external credential store can back it ([upstream README](https://github.com/Infisical/agent-vault)). | Server startup uses a master password; management UI/CLI administer vaults and rules ([upstream README](https://github.com/Infisical/agent-vault)). | Long-lived agents receive tokens; an orchestrator can mint short-lived, vault-scoped tokens for sandboxes ([upstream README](https://github.com/Infisical/agent-vault#agent-vault-for-secure-ephemeral-sandboxes)). | Separate-host HTTPS MITM proxy substitutes real credentials only on approved outbound requests; the sandbox receives proxy variables, a token, and the proxy CA certificate, not the raw target credential ([upstream README](https://github.com/Infisical/agent-vault)). | Requires a reachable Agent Vault proxy for brokered requests. The target API also remains an online dependency. |

### Audit, dynamic-secret support, license, and same-user boundary

| Candidate | Audit / dynamic-secret capability | License and OSI result | Same-user compromise limit |
|---|---|---|---|
| **SOPS + age** | No central access audit or dynamic issuance; file revision history is external. | SOPS is MPL-2.0 and age uses the BSD 3-clause text; both are OSI-approved licenses ([SOPS license](https://github.com/getsops/sops/blob/main/LICENSE), [age license](https://github.com/FiloSottile/age/blob/main/LICENSE)). | Same-user code can invoke an available identity or read secrets from a delivered child environment/FIFO. Recipient/file splitting limits the available set but does not protect plaintext after delivery. |
| **Infisical OSS core** | PostgreSQL audit-log storage is configurable, but audit-log streaming is paid; Dynamic Secrets is explicitly a paid Enterprise feature ([environment reference](https://infisical.com/docs/self-hosting/configuration/envars), [audit streams](https://infisical.com/docs/documentation/platform/audit-log-streams/audit-log-streams), [dynamic secrets](https://infisical.com/docs/documentation/platform/dynamic-secrets/overview)). | Root license: MIT Expat outside any `ee/` directory; `ee/` is separately licensed/premium, so only the MIT core satisfies OSI-only ([license](https://github.com/Infisical/infisical/blob/main/LICENSE), [README license note](https://github.com/Infisical/infisical#license)). | Same-user code that obtains a machine client secret/token can fetch everything that identity's role/project permits; environment-injected values are plaintext to the launched trust domain. |
| **OpenBao** | Detailed request/response audit devices; OpenBao refuses requests when no enabled device can record. The database secrets engine issues leased dynamic credentials ([audit docs](https://openbao.org/docs/audit/), [database engine](https://openbao.org/docs/secrets/databases/)). | MPL-2.0, OSI-approved ([license](https://github.com/openbao/openbao/blob/main/LICENSE)). | A stolen token/SecretID can exercise its policies until use/TTL/revocation limits intervene; retrieved plaintext remains exposed within the receiving user/process domain. |
| **pass** | Optional Git change history, but no server-side read audit or dynamic issuance ([official site](https://www.passwordstore.org/)). | GPL-2.0-or-later, OSI-approved ([official license statement](https://www.passwordstore.org/#license)). | Same-user code can ask an unlocked GPG agent to decrypt any entry available to that key and can read wrapper-injected plaintext. |
| **gopass** | Git provides change history, not authoritative read auditing; no dynamic issuance ([official site](https://www.gopass.pw/)). | MIT, OSI-approved ([license](https://github.com/gopasspw/gopass/blob/master/LICENSE)). | Same-user code can invoke the available GPG agent/key for its recipients and consume any plaintext emitted by the CLI. |
| **KeePassXC** | Database analysis/history features are human-vault functions, not centralized workload access audit or dynamic issuance. | GPL-3.0, OSI-approved ([license statement](https://keepassxc.org/docs/KeePassXC_GettingStarted#_license_and_disclaimers)). | Once the database/client is unlocked, same-user automation can query the CLI/client or capture copied/emitted plaintext; entry grouping is not a workload authorization boundary. |
| **Vaultwarden** | Implements organization event logs, but no dynamic-secret engine is claimed by the upstream project ([feature list](https://github.com/dani-garcia/vaultwarden#features)). | AGPL-3.0, OSI-approved ([license](https://github.com/dani-garcia/vaultwarden/blob/main/LICENSE.txt)). | Same-user code can use an unlocked client/session or its API credentials to retrieve the vault scope available to that account. |
| **Varlock** | Validation, redaction, and leak prevention are documented; audit and dynamic issuance come only from a selected backend/plugin ([upstream README](https://github.com/dmno-dev/varlock)). | MIT, OSI-approved ([license](https://github.com/dmno-dev/varlock/blob/main/LICENSE)). | Redaction reduces accidental log disclosure, not deliberate same-user exfiltration; code can inspect injected values or invoke the same backend credential. |
| **dotenvx** | No central access audit or dynamic issuance in the encrypted-dotenv flow. | BSD-3-Clause, OSI-approved ([license](https://github.com/dotenvx/dotenvx/blob/main/LICENSE)). | The private key or runtime-injected environment is the root; same-user code that can read/use either can decrypt/exfiltrate the scoped file. |
| **systemd credentials** | No cross-host secret audit or dynamic engine; it is a host service-delivery mechanism. | The upstream repository carries the LGPL-2.1 license text, an OSI-approved license ([license](https://github.com/systemd/systemd/blob/main/LICENSE.LGPL2.1)). | Service-directory isolation reduces accidental inheritance, but code with equivalent host user privileges or control of the unit can access the delivered credential. |
| **CyberArk Conjur OSS** | The OSS repository documents policy-controlled access and built-in/custom variable rotators. A general leased dynamic-secret engine is not documented there; authoritative OSS access-audit behavior was not established from the current upstream repository ([rotators](https://github.com/cyberark/conjur/blob/master/design/ROTATORS.md), [README](https://github.com/cyberark/conjur)). | LGPL-3.0, OSI-approved ([license](https://github.com/cyberark/conjur/blob/master/LICENSE.md)). | Same-user code holding a Conjur API key/token can retrieve everything allowed by that role; retrieved values remain plaintext to the consumer. |
| **HashiCorp Vault Community** | Community edition includes audit logs and dynamic secret engines ([current edition matrix](https://developer.hashicorp.com/vault/tutorials/get-started/available-editions)). | Vault 1.15.0+ is BSL-1.1 and changes to MPL-2.0 four years after each version's publication. BSL-1.1 is not on the OSI-approved license list, so current Community releases are **excluded by an OSI-only requirement** ([current license](https://github.com/hashicorp/vault/blob/main/LICENSE), [OSI-approved licenses](https://opensource.org/licenses)). | Same-user code holding a Vault token or using an available auth credential can exercise its policy and read any returned plaintext. |
| **Bitwarden Secrets Manager** | Audit logs are a Teams/Enterprise subscription feature; the documented store issues static secrets rather than leased dynamic credentials ([FAQ](https://bitwarden.com/help/secrets-manager-faqs/)). | The server repository is mixed: AGPL-3.0 by default plus Bitwarden License code under `bitwarden_license/`; self-hosted Secrets Manager additionally requires an organization license. The product therefore cannot be treated as an entirely OSI-only deployment ([server licensing notice](https://github.com/bitwarden/server/blob/main/LICENSE.txt), [FAQ](https://bitwarden.com/help/secrets-manager-faqs/)). | A same-user process with the machine access token can fetch its projects; `bws run` explicitly gives the launched command plaintext and is not a sandbox ([CLI warning](https://bitwarden.com/help/secrets-manager-cli/#run)). |
| **Infisical Agent Vault** | Request logging and per-agent egress/service rules are built in. The local vault is static; external Infisical can add dynamic secrets ([upstream README](https://github.com/Infisical/agent-vault)). | MIT Expat outside any `ee/` directory; only that core is OSI-eligible ([license](https://github.com/Infisical/agent-vault/blob/main/LICENSE)). The README marks the project **Preview**, under active development, with an API subject to change ([preview notice](https://github.com/Infisical/agent-vault#security)). | A separate host prevents the agent from possessing raw credentials, which is materially different from injection. A same-user attacker inside the sandbox can still use the agent token/proxy within its egress rules; strict `unmatched_host_policy=deny` is required because unmatched hosts forward by default ([proxy controls](https://github.com/Infisical/agent-vault#how-it-works)). |

## Load-bearing edition and product findings

- **Infisical free self-hosted designs cannot rely on custom roles or trusted-IP restrictions.** Built-in Admin/Member/Viewer/No Access roles are available to free self-hosted instances, while custom roles are Enterprise; Universal Auth client-secret and access-token trusted-IP restrictions are paid ([RBAC](https://infisical.com/docs/documentation/platform/access-controls/role-based-access-controls), [Universal Auth](https://infisical.com/docs/documentation/platform/identities/universal-auth)). Project separation plus the built-in Viewer role is the documented free-core scoping primitive; that is coarser than a custom policy.
- **Infisical dynamic secrets are not part of the MIT-only baseline.** Current documentation labels them paid/Enterprise for self-hosting, and audit-log *streaming* is paid too ([dynamic secrets](https://infisical.com/docs/documentation/platform/dynamic-secrets/overview), [audit streams](https://infisical.com/docs/documentation/platform/audit-log-streams/audit-log-streams)).
- **Varlock is a schema/injection/redaction layer, not the canonical encrypted vault.** It validates and injects configuration and can pull from backend plugins; the backend remains responsible for storing and authorizing the secret ([README](https://github.com/dmno-dev/varlock), [plugins](https://varlock.dev/plugins/overview/)).
- **dotenvx is encrypted dotenv plus runtime injection.** Its local workflow stores ciphertext in `.env`, keeps a separate private key, and decrypts/injects through `dotenvx run`; protection collapses to control of the private key and receiving process ([encryption guide](https://dotenvx.com/docs/quickstart/encryption/)).
- **pass, gopass, KeePassXC, and Vaultwarden are useful human/local vaults but do not document a first-class workload identity boundary comparable to AppRole, a machine identity, or a machine account.** Automation necessarily reuses human/local unlock material or a broad account/API session ([pass](https://www.passwordstore.org/), [gopass](https://www.gopass.pw/), [KeePassXC CLI](https://github.com/keepassxreboot/keepassxc/blob/develop/docs/man/keepassxc-cli.1.adoc), [Vaultwarden](https://github.com/dani-garcia/vaultwarden)).
- **systemd credentials are a per-service delivery complement, not a cross-host manager.** The credential directory avoids normal environment inheritance and encrypted blobs can be host/TPM-bound, but systemd does not distribute inventory or issue workload identities across hosts ([credentials specification](https://systemd.io/CREDENTIALS/)).
- **Agent Vault is future/experimental evidence, not a stable baseline.** It has the strongest raw-credential non-possession model in this set—separate-host proxying, service/path egress rules, short-lived scoped agent tokens, and a sandbox-mounted proxy CA—but upstream explicitly says Preview/API subject to change. Strict unmatched-host denial is opt-in rather than the default ([README and preview notice](https://github.com/Infisical/agent-vault)).

## Tailscale boundary

Tailscale ACLs/grants are deny-by-default reachability policy after the initial all-devices default is replaced, and enforcement occurs locally on destination devices ([ACL documentation](https://tailscale.com/docs/features/access-control/acls)). Tailscale Serve can proxy a tailnet-only service and applies tailnet access rules; it also adds Tailscale identity headers and removes spoofed inbound copies. Those headers become an authentication signal only when a backend deliberately trusts the Serve proxy, and Tailscale recommends binding such a backend to localhost to prevent direct header forgery ([Serve identity headers](https://tailscale.com/docs/features/tailscale-serve#identity-headers)).

Therefore, tailnet reachability reduces network exposure but does **not automatically map a Tailscale user/device into Infisical projects, OpenBao policies, Conjur roles, or another product's machine identity**. Each manager still needs its own human/workload authentication unless it is deliberately integrated with and securely trusts a Tailscale authentication-proxy signal. A tailnet ACL is not a substitute for product authorization.

## Concrete scenario checks

| Scenario | Expected result |
|---|---|
| An unrelated package is launched from the current interactive Fish shell | `config.fish` has already sourced `secrets.fish`; every value that file exported is inherited by the package and its descendants. Git ignore status is irrelevant at runtime. |
| A package is launched outside a SOPS, Infisical, or OpenBao wrapper after migration | It receives no managed secret. Decryption/fetch happens only inside the trusted launcher, and the parent shell never receives the values. |
| Agent A is compromised | A can use every value injected into A and every capability authorized by A's recipient/project/policy. It cannot obtain agent B's file, Infisical project, or OpenBao path unless host isolation or policy assignment is also broken. |
| The manager or tailnet path is unavailable | SOPS + age still decrypts from local ciphertext and identity. Infisical and OpenBao cannot serve a fresh fetch/login; already running processes retain plaintext previously delivered to them. |

These outcomes are architecture invariants, not redaction promises. A wrapper scopes possession; it does not make a secret safe after delivery.

## Facts not established from current primary sources

- The current Conjur OSS repository establishes policies, authenticators, encrypted PostgreSQL storage, and rotators, but this review did not establish authoritative OSS access-audit semantics or a general leased dynamic-secret engine. Enterprise documentation must not be projected onto Conjur OSS without a matching OSS source.
- Vaultwarden documents Bitwarden-compatible clients, organization event logs, and personal API keys, but does not claim Bitwarden Secrets Manager machine accounts. Treating Vaultwarden as a self-hosted Secrets Manager substitute would be unsupported.
- Infisical's current environment reference proves PostgreSQL audit-log storage exists, while its Audit Log Streams page proves streaming is paid. It does not, by itself, establish the free tier's UI retention/query limits; no free-tier promise is made here.

## Primary sources

Checked 2026-08-18; only official project documentation, upstream source repositories/licenses, and the OSI license index were used.

- SOPS: [repository/README](https://github.com/getsops/sops), [creation-rule source](https://github.com/getsops/sops/blob/main/config/config.go), [age identity loader and `SOPS_AGE_KEY_CMD`](https://github.com/getsops/sops/blob/main/age/keysource.go), [current CLI source](https://github.com/getsops/sops/blob/main/cmd/sops/main.go), [MPL-2.0 license](https://github.com/getsops/sops/blob/main/LICENSE)
- age: [repository/README](https://github.com/FiloSottile/age), [manual and passphrase-encrypted identity files](https://github.com/FiloSottile/age/blob/main/doc/age.1.ronn), [optional batchpass plugin](https://github.com/FiloSottile/age/blob/main/doc/age-plugin-batchpass.1.ronn), [`age-plugin-yubikey`](https://github.com/str4d/age-plugin-yubikey), [BSD license](https://github.com/FiloSottile/age/blob/main/LICENSE)
- Infisical: [repository/README](https://github.com/Infisical/infisical), [root license](https://github.com/Infisical/infisical/blob/main/LICENSE), [Docker Compose](https://infisical.com/docs/self-hosting/deployment-options/docker-compose), [environment variables](https://infisical.com/docs/self-hosting/configuration/envars), [machine identities](https://infisical.com/docs/documentation/platform/identities/machine-identities), [Universal Auth](https://infisical.com/docs/documentation/platform/identities/universal-auth), [RBAC](https://infisical.com/docs/documentation/platform/access-controls/role-based-access-controls), [`infisical run`](https://infisical.com/docs/cli/commands/run), [dynamic secrets](https://infisical.com/docs/documentation/platform/dynamic-secrets/overview), [audit streams](https://infisical.com/docs/documentation/platform/audit-log-streams/audit-log-streams)
- OpenBao: [repository](https://github.com/openbao/openbao), [MPL-2.0 license](https://github.com/openbao/openbao/blob/main/LICENSE), [AppRole](https://openbao.org/docs/auth/approle/), [Agent auto-auth](https://openbao.org/docs/agent-and-proxy/autoauth/), [audit devices](https://openbao.org/docs/audit/), [Raft storage](https://openbao.org/docs/configuration/storage/raft/), [Raft snapshots](https://openbao.org/docs/commands/operator/raft/), [seal model](https://openbao.org/docs/concepts/seal/), [database secrets](https://openbao.org/docs/secrets/databases/)
- pass: [official site, model, and license](https://www.passwordstore.org/)
- gopass: [official site](https://www.gopass.pw/), [upstream repository](https://github.com/gopasspw/gopass), [MIT license](https://github.com/gopasspw/gopass/blob/master/LICENSE)
- KeePassXC: [getting-started guide](https://keepassxc.org/docs/KeePassXC_GettingStarted), [upstream CLI manual](https://github.com/keepassxreboot/keepassxc/blob/develop/docs/man/keepassxc-cli.1.adoc), [GPL-3.0 license](https://github.com/keepassxreboot/keepassxc/blob/master/LICENSE.GPL-3)
- Vaultwarden: [upstream README/features](https://github.com/dani-garcia/vaultwarden), [AGPL-3.0 license](https://github.com/dani-garcia/vaultwarden/blob/main/LICENSE.txt)
- Varlock: [upstream README](https://github.com/dmno-dev/varlock), [plugins](https://varlock.dev/plugins/overview/), [MIT license](https://github.com/dmno-dev/varlock/blob/main/LICENSE)
- dotenvx: [upstream repository](https://github.com/dotenvx/dotenvx), [encryption workflow](https://dotenvx.com/docs/quickstart/encryption/), [BSD-3-Clause license](https://github.com/dotenvx/dotenvx/blob/main/LICENSE)
- systemd credentials: [credential specification](https://systemd.io/CREDENTIALS/), [LGPL-2.1 license](https://github.com/systemd/systemd/blob/main/LICENSE.LGPL2.1)
- CyberArk Conjur OSS: [upstream repository/architecture](https://github.com/cyberark/conjur), [rotator design](https://github.com/cyberark/conjur/blob/master/design/ROTATORS.md), [LGPL-3.0 license](https://github.com/cyberark/conjur/blob/master/LICENSE.md)
- HashiCorp Vault: [Community/Enterprise matrix](https://developer.hashicorp.com/vault/tutorials/get-started/available-editions), [BSL-1.1 license and change terms](https://github.com/hashicorp/vault/blob/main/LICENSE)
- Bitwarden Secrets Manager: [FAQ/plans/self-host license note](https://bitwarden.com/help/secrets-manager-faqs/), [CLI, machine-account scoping, and injection warnings](https://bitwarden.com/help/secrets-manager-cli/), [mixed server licensing notice](https://github.com/bitwarden/server/blob/main/LICENSE.txt)
- Infisical Agent Vault: [upstream README, controls, and preview notice](https://github.com/Infisical/agent-vault), [root license](https://github.com/Infisical/agent-vault/blob/main/LICENSE)
- Tailscale: [ACLs](https://tailscale.com/docs/features/access-control/acls), [Serve and identity headers](https://tailscale.com/docs/features/tailscale-serve)
- OSI: [approved licenses index](https://opensource.org/licenses)
