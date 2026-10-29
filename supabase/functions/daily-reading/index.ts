// POST { date: "YYYY-MM-DD", timezone: "Asia/Dhaka" } → { reading }
// Calculates the sky for the user's local noon on [date], compares it with
// their birth chart and stores the result in daily_readings (one per day).
import { error, getCaller, json, userClient } from "../_shared/http.ts";
import { birthToUtc, skyAt, transitAspects } from "../astrology-chart/chart.ts";

Deno.serve(async (req) => {
  if (req.method !== "POST") return error("Method not allowed", 405);

  const client = userClient(req);
  const user = await getCaller(client);
  if (!user) return error("Not signed in", 401);

  let date: unknown;
  let timezone: unknown;
  try {
    ({ date, timezone } = await req.json());
  } catch {
    return error("Body must be JSON", 400);
  }
  if (typeof date !== "string" || !/^\d{4}-\d{2}-\d{2}$/.test(date)) {
    return error("date must be YYYY-MM-DD", 400);
  }
  const tz = typeof timezone === "string" && timezone ? timezone : "UTC";

  // The user's birth chart (row-level security limits this to their own).
  const { data: profile } = await client
    .from("birth_profiles")
    .select("id, astrology_results(planet_data, ascendant_longitude, mc_longitude)")
    .eq("user_id", user.id)
    .maybeSingle();
  const natalRow = Array.isArray(profile?.astrology_results)
    ? profile?.astrology_results[0]
    : profile?.astrology_results;
  if (!natalRow) return error("Calculate your birth chart first", 404);

  const natal: Record<string, number> = {};
  for (const p of natalRow.planet_data as { name: string; longitude: number }[]) {
    if (p.name !== "North Node") natal[p.name] = p.longitude;
  }
  if (natalRow.ascendant_longitude != null) natal.Ascendant = natalRow.ascendant_longitude;
  if (natalRow.mc_longitude != null) natal.Midheaven = natalRow.mc_longitude;

  let when: Date;
  try {
    when = birthToUtc({ birthDate: date, birthTime: "12:00", timezone: tz, latitude: 0, longitude: 0 });
  } catch {
    return error(`Unknown timezone "${tz}"`, 422);
  }
  const sky = skyAt(when);
  const moon = sky.planets.find((p) => p.name === "Moon")!;
  const data = {
    moon: { sign: moon.sign, ...sky.moonPhase },
    planets: sky.planets.map(({ name, sign, retrograde, longitude }) => ({ name, sign, retrograde, longitude })),
    transits: transitAspects(sky.planets, natal).slice(0, 8),
    retrogrades: sky.planets.filter((p) => p.retrograde).map((p) => p.name),
  };

  const { data: saved, error: writeError } = await client
    .from("daily_readings")
    .upsert({ user_id: user.id, reading_date: date, data }, { onConflict: "user_id,reading_date" })
    .select()
    .single();
  if (writeError) return error("Could not save the reading", 500);
  return json({ reading: saved });
});
