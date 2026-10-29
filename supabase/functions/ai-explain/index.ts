// POST <calculated results> → { explanation }
// Turns results the app already calculated (chart signs, Kua number, rule-
// based room advice) into a friendly reading. The model only explains; it
// never calculates positions or picks directions.
import Anthropic from "npm:@anthropic-ai/sdk@1.3.0";
import { error, getCaller, json, userClient } from "../_shared/http.ts";

const MAX_BODY_BYTES = 20_000;

const SYSTEM_PROMPT = `You write the "Personalized reading" in Astro Home, an app that pairs a person's birth chart with traditional feng shui for their room.

You receive JSON with results that the app has already calculated: Sun, Moon and rising signs, the strongest and weakest elements, the feng shui Kua number, the room's facing direction, and rule-based advice for each piece of furniture (its current zone, a verdict, and sometimes a suggested zone), plus colour, decor and direction suggestions.

Your job is to explain those results warmly and simply, as a knowledgeable friend would. Work only from the data given:
- Do not calculate or guess planet positions, signs, houses, Kua numbers or compass directions, and do not add placements or directions that are not in the data. If something is missing (for example no rising sign), say it needs that detail rather than inventing it.
- Keep every recommendation consistent with the given verdicts and suggested zones.

Write about 180–280 words in plain English, in short paragraphs: first what the chart suggests about how this person likes a home to feel, then the one to three furniture changes that matter most and why, then a closing line on colours or decor. Address the reader as "you". No headings, lists or markdown. Present feng shui and astrology as traditions for inspiration, not as scientific fact.`;

let client: Anthropic | null = null;

Deno.serve(async (req) => {
  if (req.method !== "POST") return error("Method not allowed", 405);

  // Created on first use, so the function still starts before the key is set.
  const apiKey = Deno.env.get("ANTHROPIC_API_KEY");
  if (!apiKey) return error("The assistant is not configured yet.", 503);
  client ??= new Anthropic({ apiKey });

  // Only signed-in users may spend AI credits.
  const user = await getCaller(userClient(req));
  if (!user) return error("Not signed in", 401);

  const raw = await req.text();
  if (raw.length > MAX_BODY_BYTES) return error("Request too large", 413);
  let payload: Record<string, unknown>;
  try {
    payload = JSON.parse(raw);
  } catch {
    return error("Body must be JSON", 400);
  }
  if (!payload || typeof payload !== "object" || !("room" in payload)) {
    return error("Missing calculated room data", 400);
  }

  try {
    const response = await client.beta.messages.create({
      model: "claude-opus-5-5",
      max_tokens: 16000,
      // A short, friendly reading does not need deep reasoning.
      output_config: { effort: "low" },
      // If the model declines, the API retries on Anthropic's recommended
      // fallback model inside the same call.
      betas: ["server-side-fallback-2026-07-01"],
      fallbacks: "default",
      system: SYSTEM_PROMPT,
      messages: [
        {
          role: "user",
          content: `Calculated results:\n${JSON.stringify(payload, null, 2)}`,
        },
      ],
    });

    if (response.stop_reason === "refusal") {
      return error("The assistant could not write a reading for this request.", 422);
    }
    const text = response.content
      .flatMap((block) => (block.type === "text" ? [block.text] : []))
      .join("\n")
      .trim();
    if (!text) return error("The assistant returned an empty reading.", 502);

    return json({ explanation: text });
  } catch (e) {
    if (e instanceof Anthropic.RateLimitError) {
      return error("The assistant is busy right now. Try again in a minute.", 429);
    }
    if (e instanceof Anthropic.AuthenticationError) {
      console.error("ai-explain: Anthropic key missing or invalid");
      return error("The assistant is not configured.", 503);
    }
    if (e instanceof Anthropic.APIError) {
      console.error(`ai-explain: Anthropic API error ${e.status}`);
      return error("The assistant had a problem. Please try again.", 502);
    }
    console.error("ai-explain: unexpected error", e);
    return error("The assistant had a problem. Please try again.", 500);
  }
});
