import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

export default function (pi: ExtensionAPI) {
  pi.on("before_provider_request", (event, ctx) => {
    // Kimi's coding endpoint rejects the OpenAI `developer` role. The CPA
    // provider otherwise uses Pi's generic reasoning-model serialization.
    if (ctx.model?.provider !== "cpa" || !ctx.model.id.startsWith("kimi-")) return;
    if (!isRecord(event.payload) || !Array.isArray(event.payload.messages)) return;

    let changed = false;
    const messages = event.payload.messages.map((message) => {
      if (!isRecord(message) || message.role !== "developer") return message;
      changed = true;
      return { ...message, role: "system" };
    });

    return changed ? { ...event.payload, messages } : undefined;
  });
}
