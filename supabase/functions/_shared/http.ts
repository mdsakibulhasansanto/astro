// Helpers shared by the Edge Functions.
import { createClient, type SupabaseClient, type User } from "jsr:@supabase/supabase-js@2";

export const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });

export const error = (message: string, status: number) => json({ error: message }, status);

/** Reads a key from the legacy variable, or the first entry of the newer
 * JSON map (SUPABASE_PUBLISHABLE_KEYS / SUPABASE_SECRET_KEYS). */
function envKey(legacy: string, map: string): string {
  const direct = Deno.env.get(legacy);
  if (direct) return direct;
  try {
    const keys = JSON.parse(Deno.env.get(map) ?? "{}") as Record<string, string>;
    const first = keys.default ?? Object.values(keys)[0];
    if (first) return first;
  } catch {
    // fall through
  }
  throw new Error(`Missing ${legacy} / ${map}`);
}

/** Supabase client acting as the caller, so row-level security applies. */
export function userClient(req: Request): SupabaseClient {
  const key = envKey("SUPABASE_ANON_KEY", "SUPABASE_PUBLISHABLE_KEYS");
  return createClient(Deno.env.get("SUPABASE_URL")!, key, {
    global: { headers: { Authorization: req.headers.get("Authorization") ?? "" } },
    auth: { persistSession: false },
  });
}

/** Service-role client. Bypasses row-level security; use only for writes
 * the caller is not allowed to make directly. */
export function adminClient(): SupabaseClient {
  const key = envKey("SUPABASE_SERVICE_ROLE_KEY", "SUPABASE_SECRET_KEYS");
  return createClient(Deno.env.get("SUPABASE_URL")!, key, {
    auth: { persistSession: false },
  });
}

/** The signed-in caller, or null when the token is missing or invalid. */
export async function getCaller(client: SupabaseClient): Promise<User | null> {
  const { data, error } = await client.auth.getUser();
  return error ? null : data.user;
}
