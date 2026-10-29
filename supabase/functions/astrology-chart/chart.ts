// Birth chart calculation with astronomy-engine (the same library as the
// Astro Home prototype). Pure: no I/O, so it can be tested on its own.
//
// Produces planet positions, Placidus houses, Ascendant and Midheaven,
// major aspects, the Moon phase at birth, the mean lunar node and the
// element and modality balance.
import * as Astronomy from "npm:astronomy-engine@2.1.19";

export const SIGNS = [
  ["Aries", "Fire", "Cardinal"], ["Taurus", "Earth", "Fixed"], ["Gemini", "Air", "Mutable"],
  ["Cancer", "Water", "Cardinal"], ["Leo", "Fire", "Fixed"], ["Virgo", "Earth", "Mutable"],
  ["Libra", "Air", "Cardinal"], ["Scorpio", "Water", "Fixed"], ["Sagittarius", "Fire", "Mutable"],
  ["Capricorn", "Earth", "Cardinal"], ["Aquarius", "Air", "Fixed"], ["Pisces", "Water", "Mutable"],
] as const;

const BODIES = [
  "Sun", "Moon", "Mercury", "Venus", "Mars", "Jupiter", "Saturn", "Uranus", "Neptune", "Pluto",
] as const;

// Sun, Moon and Rising count most toward the element and modality balance.
const WEIGHT: Record<string, number> = {
  Sun: 3, Moon: 3, Asc: 2, Mercury: 1, Venus: 1, Mars: 1, Jupiter: 1, Saturn: 1,
};

/** Major (Ptolemaic) aspects and their allowed orbs in degrees. */
const ASPECTS = [
  { type: "conjunction", angle: 0, orb: 8 },
  { type: "sextile", angle: 60, orb: 4.5 },
  { type: "square", angle: 90, orb: 7 },
  { type: "trine", angle: 120, orb: 7 },
  { type: "opposition", angle: 180, orb: 8 },
] as const;

/** Points that take part in aspects. */
const ASPECT_POINTS = [...BODIES, "Ascendant", "Midheaven"];

export interface BirthInput {
  birthDate: string; // YYYY-MM-DD, local
  birthTime: string | null; // HH:mm or HH:mm:ss, local; null if unknown
  timezone: string; // IANA id
  latitude: number;
  longitude: number;
}

export interface PlanetRow {
  name: string;
  longitude: number;
  sign: string;
  house: number | null;
  retrograde: boolean;
  /** Degrees per day along the zodiac (negative when retrograde). */
  speed: number;
}

export interface AspectRow {
  a: string;
  b: string;
  type: string;
  /** Actual angle between the two points. */
  angle: number;
  /** Distance from exact, in degrees. */
  orb: number;
  /** True when the faster point is moving toward exact. */
  applying: boolean | null;
}

export interface ChartResult {
  sun_sign: string;
  moon_sign: string;
  ascendant: string | null;
  ascendant_longitude: number | null;
  mc_longitude: number | null;
  house_system: "placidus" | null;
  planet_data: PlanetRow[];
  houses: { house: number; sign: string; cusp: number }[];
  aspects: AspectRow[];
  element_balance: Record<string, number>;
  modality_balance: Record<string, number>;
  dominant_element: string;
  weakest_element: string;
  moon_phase: { name: string; angle: number; illumination: number };
  utc_time: string;
}

const norm = (a: number) => ((a % 360) + 360) % 360;
const rad = (d: number) => (d * Math.PI) / 180;
const deg = (r: number) => (r * 180) / Math.PI;
const round = (v: number, p = 4) => Math.round(v * 10 ** p) / 10 ** p;
export const signIndex = (lon: number) => Math.floor(norm(lon) / 30) % 12;

/** Offset of [tz] from UTC (ms) at instant [ms]. Throws on an unknown tz. */
function tzOffsetMs(ms: number, tz: string): number {
  const parts: Record<string, string> = {};
  new Intl.DateTimeFormat("en-US", {
    timeZone: tz,
    hourCycle: "h23",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
  }).formatToParts(new Date(ms)).forEach((p) => (parts[p.type] = p.value));
  const asUtc = Date.UTC(
    +parts.year, +parts.month - 1, +parts.day, +parts.hour % 24, +parts.minute, +parts.second,
  );
  return asUtc - Math.floor(ms / 1000) * 1000;
}

/** Converts a local birth date/time in an IANA zone to a UTC Date. */
export function birthToUtc(input: BirthInput): Date {
  const [y, mo, d] = input.birthDate.split("-").map(Number);
  // Without a time, noon keeps the Moon within about 7° of its real place.
  const [h, mi] = (input.birthTime ?? "12:00").split(":").map(Number);
  if ([y, mo, d, h, mi].some((n) => !Number.isFinite(n))) {
    throw new Error("Invalid birth date or time");
  }
  const wall = Date.UTC(y, mo - 1, d, h, mi);
  let guess = wall;
  for (let i = 0; i < 3; i++) guess = wall - tzOffsetMs(guess, input.timezone);
  return new Date(guess);
}

function eclipticLongitude(body: string, time: Astronomy.AstroTime): number {
  return norm(Astronomy.Ecliptic(Astronomy.GeoVector(body as Astronomy.Body, time, true)).elon);
}

/** Mean lunar node (Meeus 22). Always moves backward. */
function meanNode(t: Astronomy.AstroTime): number {
  const T = t.tt / 36525;
  return norm(125.04452 - 1934.136261 * T + 0.0020708 * T * T + (T * T * T) / 450000);
}

/** Ecliptic longitude of the point on the ecliptic with right ascension [ra]. */
function raToLongitude(raDeg: number, eps: number): number {
  return norm(deg(Math.atan2(Math.sin(rad(raDeg)), Math.cos(rad(raDeg)) * Math.cos(eps))));
}

/**
 * Placidus house cusps (longitudes, index 0 = house 1). Cusps 11, 12, 2
 * and 3 divide each quadrant's semi-arc into thirds, found by iteration.
 */
export function placidusCusps(ramcDeg: number, eps: number, phi: number, asc: number): number[] {
  const mc = raToLongitude(ramcDeg, eps);
  // fraction of the semi-arc, and whether it is the diurnal (above) arc
  const solve = (fraction: number, above: boolean): number => {
    // Start as if the semi-arcs were 90°, then refine.
    let ra = ramcDeg + (above ? fraction * 90 : 180 - fraction * 90);
    for (let i = 0; i < 50; i++) {
      const lon = raToLongitude(ra, eps);
      const dec = Math.asin(Math.sin(eps) * Math.sin(rad(lon)));
      const x = Math.tan(phi) * Math.tan(dec);
      const ad = deg(Math.asin(Math.max(-1, Math.min(1, x))));
      const next = above
        ? ramcDeg + fraction * (90 + ad) // part of the diurnal semi-arc
        : ramcDeg + 180 - fraction * (90 - ad); // part of the nocturnal semi-arc
      if (Math.abs(norm(next - ra + 180) - 180) < 1e-7) {
        ra = next;
        break;
      }
      ra = next;
    }
    return raToLongitude(ra, eps);
  };
  const c11 = solve(1 / 3, true);
  const c12 = solve(2 / 3, true);
  const c2 = solve(2 / 3, false);
  const c3 = solve(1 / 3, false);
  const cusps = [asc, c2, c3, norm(mc + 180), norm(c11 + 180), norm(c12 + 180),
    norm(asc + 180), norm(c2 + 180), norm(c3 + 180), mc, c11, c12];
  return cusps.map((c) => norm(c));
}

/** House (1–12) containing [lon], given cusps in house order. */
export function houseOf(lon: number, cusps: number[]): number {
  for (let i = 0; i < 12; i++) {
    const start = cusps[i];
    const end = cusps[(i + 1) % 12];
    const span = norm(end - start);
    if (norm(lon - start) < span) return i + 1;
  }
  return 1;
}

function phaseName(angle: number): string {
  const names = [
    "New Moon", "Waxing Crescent", "First Quarter", "Waxing Gibbous",
    "Full Moon", "Waning Gibbous", "Last Quarter", "Waning Crescent",
  ];
  return names[Math.round(norm(angle) / 45) % 8];
}

function findAspects(points: Record<string, { lon: number; speed: number }>): AspectRow[] {
  const names = ASPECT_POINTS.filter((n) => points[n] != null);
  const out: AspectRow[] = [];
  for (let i = 0; i < names.length; i++) {
    for (let j = i + 1; j < names.length; j++) {
      const a = names[i];
      const b = names[j];
      if ((a === "Ascendant" || a === "Midheaven") && (b === "Ascendant" || b === "Midheaven")) continue;
      const pa = points[a];
      const pb = points[b];
      const sep = Math.abs(norm(pa.lon - pb.lon + 180) - 180); // 0–180
      for (const asp of ASPECTS) {
        // Wider orbs when the Sun or Moon is involved.
        const lights = [a, b].some((n) => n === "Sun" || n === "Moon");
        const allowed = asp.orb + (lights ? 1 : 0);
        const orb = Math.abs(sep - asp.angle);
        if (orb <= allowed) {
          // Applying: the separation is moving toward the exact angle.
          let applying: boolean | null = null;
          if (pa.speed !== 0 || pb.speed !== 0) {
            const dt = 0.01;
            const sep2 = Math.abs(
              norm(pa.lon + pa.speed * dt - (pb.lon + pb.speed * dt) + 180) - 180,
            );
            applying = Math.abs(sep2 - asp.angle) < orb;
          }
          out.push({ a, b, type: asp.type, angle: round(sep, 2), orb: round(orb, 2), applying });
          break;
        }
      }
    }
  }
  return out.sort((x, y) => x.orb - y.orb);
}

function balance(values: Record<string, number>): Record<string, number> {
  const total = Object.values(values).reduce((s, v) => s + v, 0) || 1;
  const out: Record<string, number> = {};
  for (const [k, v] of Object.entries(values)) out[k] = Math.round((v / total) * 100);
  return out;
}

export function calculateChart(input: BirthInput): ChartResult {
  if (Math.abs(input.latitude) > 66.5) {
    // House and ascendant formulas break down inside the polar circles.
    throw new Error("Birthplaces above 66.5° latitude are not supported");
  }
  const date = birthToUtc(input);
  const t = Astronomy.MakeTime(date);
  const tomorrow = t.AddDays(1);

  const lon: Record<string, number> = {};
  const speed: Record<string, number> = {};
  for (const body of BODIES) {
    lon[body] = eclipticLongitude(body, t);
    speed[body] = ((eclipticLongitude(body, tomorrow) - lon[body] + 540) % 360) - 180;
  }
  const node = meanNode(t);

  let asc: number | null = null;
  let mc: number | null = null;
  let cusps: number[] | null = null;
  if (input.birthTime) {
    const ramc = norm(Astronomy.SiderealTime(t) * 15 + input.longitude);
    const lst = rad(ramc);
    const T = t.tt / 36525;
    const eps = rad(23.4392911 - 0.0130042 * T);
    const phi = rad(input.latitude);
    asc = norm(
      deg(Math.atan2(Math.cos(lst), -(Math.sin(lst) * Math.cos(eps) + Math.tan(phi) * Math.sin(eps)))),
    );
    mc = raToLongitude(ramc, eps);
    cusps = placidusCusps(ramc, eps, phi, asc);
  }

  const houseFor = (l: number) => (cusps ? houseOf(l, cusps) : null);
  const planets: PlanetRow[] = BODIES.map((name) => ({
    name,
    longitude: round(lon[name]),
    sign: SIGNS[signIndex(lon[name])][0],
    house: houseFor(lon[name]),
    retrograde: name !== "Sun" && name !== "Moon" && speed[name] < 0,
    speed: round(speed[name], 4),
  }));
  planets.push({
    name: "North Node",
    longitude: round(node),
    sign: SIGNS[signIndex(node)][0],
    house: houseFor(node),
    retrograde: true,
    speed: -0.053,
  });

  const points: Record<string, { lon: number; speed: number }> = {};
  for (const body of BODIES) points[body] = { lon: lon[body], speed: speed[body] };
  if (asc != null) points.Ascendant = { lon: asc, speed: 0 };
  if (mc != null) points.Midheaven = { lon: mc, speed: 0 };

  const elements: Record<string, number> = { Fire: 0, Earth: 0, Air: 0, Water: 0 };
  const modes: Record<string, number> = { Cardinal: 0, Fixed: 0, Mutable: 0 };
  for (const [key, w] of Object.entries(WEIGHT)) {
    const l = key === "Asc" ? asc : lon[key];
    if (l == null) continue;
    const s = SIGNS[signIndex(l)];
    elements[s[1]] += w;
    modes[s[2]] += w;
  }
  const order = Object.keys(elements).sort((a, b) => elements[b] - elements[a]);

  const phaseAngle = Astronomy.MoonPhase(t);
  const illumination = Astronomy.Illumination(Astronomy.Body.Moon, t).phase_fraction;

  return {
    sun_sign: SIGNS[signIndex(lon.Sun)][0],
    moon_sign: SIGNS[signIndex(lon.Moon)][0],
    ascendant: asc == null ? null : SIGNS[signIndex(asc)][0],
    ascendant_longitude: asc == null ? null : round(asc),
    mc_longitude: mc == null ? null : round(mc),
    house_system: cusps ? "placidus" : null,
    planet_data: planets,
    houses: cusps
      ? cusps.map((c, i) => ({ house: i + 1, sign: SIGNS[signIndex(c)][0], cusp: round(c) }))
      : [],
    aspects: findAspects(points),
    element_balance: balance(elements),
    modality_balance: balance(modes),
    dominant_element: order[0],
    weakest_element: order[order.length - 1],
    moon_phase: {
      name: phaseName(phaseAngle),
      angle: round(phaseAngle, 2),
      illumination: round(illumination, 3),
    },
    utc_time: date.toISOString(),
  };
}

/** Positions of the ten planets at [date] (for daily transits). */
export function skyAt(date: Date): {
  planets: { name: string; longitude: number; sign: string; speed: number; retrograde: boolean }[];
  moonPhase: { name: string; angle: number; illumination: number };
} {
  const t = Astronomy.MakeTime(date);
  const tomorrow = t.AddDays(1);
  const planets = BODIES.map((name) => {
    const lon = eclipticLongitude(name, t);
    const speed = ((eclipticLongitude(name, tomorrow) - lon + 540) % 360) - 180;
    return {
      name,
      longitude: round(lon),
      sign: SIGNS[signIndex(lon)][0],
      speed: round(speed, 4),
      retrograde: name !== "Sun" && name !== "Moon" && speed < 0,
    };
  });
  const angle = Astronomy.MoonPhase(t);
  return {
    planets,
    moonPhase: {
      name: phaseName(angle),
      angle: round(angle, 2),
      illumination: round(Astronomy.Illumination(Astronomy.Body.Moon, t).phase_fraction, 3),
    },
  };
}

/** Today's planets in aspect to birth-chart points, tightest first. */
export function transitAspects(
  transits: { name: string; longitude: number }[],
  natal: Record<string, number>,
): { transit: string; natal: string; type: string; orb: number }[] {
  // Fast movers get wider orbs: they pass quickly.
  const orbFor = (name: string) =>
    name === "Moon" ? 5 : name === "Sun" || name === "Mercury" || name === "Venus" ? 3 : 2;
  const out: { transit: string; natal: string; type: string; orb: number }[] = [];
  for (const t of transits) {
    for (const [n, lon] of Object.entries(natal)) {
      const sep = Math.abs(norm(t.longitude - lon + 180) - 180);
      for (const asp of ASPECTS) {
        const orb = Math.abs(sep - asp.angle);
        if (orb <= orbFor(t.name)) {
          out.push({ transit: t.name, natal: n, type: asp.type, orb: round(orb, 2) });
          break;
        }
      }
    }
  }
  return out.sort((a, b) => a.orb - b.orb);
}
