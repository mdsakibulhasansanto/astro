// POST { profile_id } → { result }
// Reads the caller's birth profile, calculates the chart and stores it in
// astrology_results. The app never calculates planets itself.
import { adminClient, error, getCaller, json, userClient } from "../_shared/http.ts";
import { calculateChart } from "./chart.ts";

Deno.serve(async (req) => {
  if (req.method !== "POST") return error("Method not allowed", 405);

  const client = userClient(req);
  const user = await getCaller(client);
  if (!user) return error("Not signed in", 401);

  let profileId: unknown;
  try {
    profileId = (await req.json()).profile_id;
  } catch {
    return error("Body must be JSON", 400);
  }
  if (typeof profileId !== "string") return error("profile_id is required", 400);

  // Row-level security means this only finds the caller's own profile.
  const { data: profile, error: readError } = await client
    .from("birth_profiles")
    .select("*")
    .eq("id", profileId)
    .maybeSingle();
  if (readError) return error("Could not read the birth profile", 500);
  if (!profile) return error("Birth profile not found", 404);

  let chart;
  try {
    chart = calculateChart({
      birthDate: profile.birth_date,
      birthTime: profile.birth_time,
      timezone: profile.timezone,
      latitude: profile.latitude,
      longitude: profile.longitude,
    });
  } catch (e) {
    const message = e instanceof RangeError
      ? `Unknown timezone "${profile.timezone}"`
      : e instanceof Error ? e.message : "Calculation failed";
    return error(message, 422);
  }

  const { utc_time: _utc, ...row } = chart;
  const { data: saved, error: writeError } = await adminClient()
    .from("astrology_results")
    .upsert(
      { profile_id: profile.id, ...row, calculated_at: new Date().toISOString() },
      { onConflict: "profile_id" },
    )
    .select()
    .single();
  if (writeError) return error("Could not save the chart", 500);

  return json({ result: saved });
});
