// POST { messages: [{role, content}], context: {...calculated data} } → { reply }
// Room-planning and astrology Q&A. The assistant only explains and advises
// from data the app already calculated; it never calculates positions.
import Anthropic from "npm:@anthropic-ai/sdk@1.3.0";
import { error, getCaller, json, userClient } from "../_shared/http.ts";

const MAX_MESSAGES = 16;
const MAX_MESSAGE_CHARS = 2000;
const MAX_CONTEXT_CHARS = 12_000;

const SYSTEM_PROMPT = `You are the Astro Home interior assistant inside a mobile app that combines a person's birth chart with traditional feng shui for their rooms.

You receive the user's calculated data as JSON (signs, element balance, Kua number and best directions, their rooms with facing direction and furniture, and rule-based placement advice). Answer their questions about arranging rooms, colours, decor and what their chart suggests for their space.

Rules:
- Work only from the data given and from general, traditional feng shui and astrology ideas. Never calculate or guess planet positions, signs, houses, Kua numbers or compass directions that are not in the data; if something needed is missing, say what the user should add in the app.
- Keep placement advice consistent with the rule-based verdicts in the data.
- Be practical and kind. Keep answers short: usually 2–5 sentences, or a few short bullet points for step-by-step suggestions. Plain text, no headings.
- Present astrology and feng shui as traditions for inspiration, not scientific fact. For safety, structural or electrical changes, suggest a professional.
- If the question has nothing to do with home, interiors, astrology or the app, politely steer back.`;

let client: Anthropic | null = null;

interface ChatMessage {
  role: "user" | "assistant";
  content: string;
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return error("Method not allowed", 405);

  const apiKey = Deno.env.get("ANTHROPIC_API_KEY");
  if (!apiKey) return error("The assistant is not configured yet.", 503);
  client ??= new Anthropic({ apiKey });

  const user = await getCaller(userClient(req));
  if (!user) return error("Not signed in", 401);

  let body: { messages?: unknown; context?: unknown };
  try {
    body = await req.json();
  } catch {
    return error("Body must be JSON", 400);
  }
  if (!Array.isArray(body.messages) || body.messages.length === 0) {
    return error("messages are required", 400);
  }
  const messages: ChatMessage[] = [];
  for (const m of body.messages.slice(-MAX_MESSAGES)) {
    if (
      !m || typeof m !== "object" ||
      ((m as ChatMessage).role !== "user" && (m as ChatMessage).role !== "assistant") ||
      typeof (m as ChatMessage).content !== "string"
    ) {
      return error("Each message needs a role (user/assistant) and text content", 400);
    }
    const content = (m as ChatMessage).content.trim().slice(0, MAX_MESSAGE_CHARS);
    if (content) messages.push({ role: (m as ChatMessage).role, content });
  }
  // The conversation must start with the user.
  while (messages.length && messages[0].role !== "user") messages.shift();
  if (!messages.length || messages[messages.length - 1].role !== "user") {
    return error("The last message must be from the user", 400);
  }
  const context = JSON.stringify(body.context ?? {}).slice(0, MAX_CONTEXT_CHARS);

  try {
    const response = await client.beta.messages.create({
      model: "claude-opus-5-5",
      max_tokens: 16000,
      output_config: { effort: "low" },
      betas: ["server-side-fallback-2026-07-01"],
      fallbacks: "default",
      system: `${SYSTEM_PROMPT}\n\nThe user's calculated data:\n${context}`,
      messages,
    });
    if (response.stop_reason === "refusal") {
      return error("The assistant can't help with that request.", 422);
    }
    const reply = response.content
      .flatMap((block) => (block.type === "text" ? [block.text] : []))
      .join("\n")
      .trim();
    if (!reply) return error("The assistant returned an empty reply.", 502);
    return json({ reply });
  } catch (e) {
    if (e instanceof Anthropic.RateLimitError) {
      return error("The assistant is busy right now. Try again in a minute.", 429);
    }
    if (e instanceof Anthropic.AuthenticationError) {
      console.error("ai-chat: Anthropic key missing or invalid");
      return error("The assistant is not configured.", 503);
    }
    if (e instanceof Anthropic.APIError) {
      console.error(`ai-chat: Anthropic API error ${e.status}`);
      return error("The assistant had a problem. Please try again.", 502);
    }
    console.error("ai-chat: unexpected error", e);
    return error("The assistant had a problem. Please try again.", 500);
  }
});
