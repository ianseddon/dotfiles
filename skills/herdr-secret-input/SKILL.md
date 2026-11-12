---
name: herdr-secret-input
description: Collect a secret from Ian (password, API key, token, passphrase) through a masked Herdr popup, so the value never enters the transcript. Use whenever a task needs a credential from Ian while HERDR_ENV=1.
---

# Secret input through Herdr

Ian hands over secrets in a popup, not in chat. `ask-secret` opens a masked input on whatever pane he has active, he pastes the value, and you get back the path of a private file holding it (0600, tmpfs, trimmed of surrounding whitespace, no trailing newline). You work with the **path**; the **value** stays out of your context and output from start to finish.

This needs `HERDR_ENV=1`. Without it, ask Ian to provide the secret through his own shell instead (an exported variable or a file he creates) and work with that.

## 1. Ask

Run `ask-secret` from this skill's directory, once per secret. It links the popup plugin into Herdr itself the first time. Name exactly what you need in the label, and say what it's for and what scope it needs in the reason:

```bash
f=$(<skill dir>/ask-secret "GitHub token for ianseddon" \
  --reason "Push the v1.2.0 tag to ianseddon/dotfiles; needs repo scope.")
```

It blocks until Ian answers, for up to `--timeout` seconds (default 600). Give your tool call a longer timeout than that.

| Exit | Meaning | Next |
|---|---|---|
| 0 | The file path is on stdout, `stored N bytes` on stderr | Check N, then step 2 |
| 1 | Ian cancelled or closed the popup | Ask in chat how he wants to proceed; reopen only if he says to |
| 124 | No answer before the timeout | Tell him in chat, and ask again once he replies |
| 2 | Setup error | Report the message; it names the fix |

N is your only view of the value, so check it against what the secret should look like: a GitHub classic token is 40 bytes, for example, and an OpenAI key well over 40. When N doesn't fit, tell Ian the length you got and what you expected, delete the file, and ask again.

## 2. Use

Have the shell expand the file inside the command that consumes it. Prefer stdin or an environment variable over a command-line argument, which shows up in `ps`:

| Consumer | Pattern |
|---|---|
| Reads stdin | `gh auth login --with-token < "$f"` |
| Reads an env var | `GH_TOKEN="$(cat "$f")" gh api user` |
| Password prompt on stdin | `sudo -S -v < "$f"` |
| Belongs in a file | `printf 'OPENAI_API_KEY=%s\n' "$(cat "$f")" >> .env`, then tell Ian which file now holds it |

The path itself is not secret, so you can write it literally in later commands when your shell doesn't keep `$f`. Every command that touches the file prints only its own result: no `cat "$f"` on its own, no `echo`, no `set -x`, and no reading the file with your read tool.

## 3. Clean up

Run `rm -f "$f"` once the last command that needs the secret has run, whether it succeeded or failed. If a later step needs the secret again, call `ask-secret` again. The step is done when no file of yours is left in `$XDG_RUNTIME_DIR/herdr-secrets`.
