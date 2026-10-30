import type { HunkExtensionAPI } from "hunkdiff/extension";
import {
  createVimNavigationState,
  executeVimCommand,
  type VimNavigationCommands,
  type VimNavigationKey,
} from "./state";

interface VimKeyCommand {
  id: string;
  title: string;
  key: VimNavigationKey;
}

// Hunk 0.24 keyboard modes require manual activation. Ordinary commands plus
// user keybindings provide the same grammar without a startup mode toggle.
const KEY_COMMANDS: readonly VimKeyCommand[] = [
  { id: "move-down", title: "Vim: move down", key: { sequence: "j" } },
  { id: "move-up", title: "Vim: move up", key: { sequence: "k" } },
  { id: "previous-hunk", title: "Vim: previous hunk", key: { sequence: "[" } },
  { id: "next-hunk", title: "Vim: next hunk", key: { sequence: "]" } },
  { id: "jump-bottom", title: "Vim: jump to bottom", key: { sequence: "G" } },
  { id: "prefix-g", title: "Vim: g prefix", key: { sequence: "g" } },
  { id: "prefix-z", title: "Vim: z prefix", key: { sequence: "z" } },
  { id: "half-page-down", title: "Vim: half page down", key: { name: "d", ctrl: true } },
  { id: "half-page-up", title: "Vim: half page up", key: { name: "u", ctrl: true } },
  ...Array.from({ length: 10 }, (_, digit) => ({
    id: `digit-${digit}`,
    title: `Vim: count digit ${digit}`,
    key: { sequence: String(digit) },
  })),
];

export default function (hunk: HunkExtensionAPI) {
  let activeCommands: VimNavigationCommands = { execute: () => false };
  const navigation = createVimNavigationState({
    execute: (commandId, options) => activeCommands.execute(commandId, options),
  });

  for (const command of KEY_COMMANDS) {
    hunk.registerCommand({ id: command.id, title: command.title }, (ctx) => {
      activeCommands = ctx.commands;
      const result = navigation.handleKey(command.key);
      if (command.key.sequence === "0" && result === "pass") {
        ctx.commands.execute("hunk.view.layoutAuto");
      }
    });
  }

  hunk.registerCommand({ id: "command-line", title: "Open Vim command line" }, async (ctx) => {
    navigation.handleKey({ sequence: ":" });
    const input = await ctx.prompts.line({ prefix: ":", placeholder: "top, bottom, or q" });
    if (input === null) return;

    const result = executeVimCommand(input, ctx.commands);
    if (result === "unknown") {
      ctx.notify(`Unknown command "${input.trim()}"`, "warning");
    }
  });
}
