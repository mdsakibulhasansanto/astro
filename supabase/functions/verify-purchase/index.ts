// POST { platform: "android", productId, purchaseToken } → { premium, until }
// Verifies a Google Play subscription with the Google Play Developer API and
// records Premium on the caller's profile. The app never grants Premium
// itself.
//
// Secrets (Supabase → Edge Functions → Secrets):
//   GOOGLE_PLAY_PACKAGE_NAME          e.g. com.astrohome.astro_home
//   GOOGLE_PLAY_SERVICE_ACCOUNT_JSON  the service account key JSON with
//                                      access to the app in Play Console
import { adminClient, error, getCaller, json, userClient } from "../_shared/http.ts";

interface ServiceAccount {
  client_email: string;
  private_key: string;
}

const b64url = (data: ArrayBuffer | Uint8Array | string) => {
  const bytes = typeof data === "string" ? new TextEncoder().encode(data) : new Uint8Array(data);
  let s = "";
  for (const b of bytes) s += String.fromCharCode(b);
  return btoa(s).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
};

/** OAuth access token for the Play Developer API, from a service account. */
async function googleAccessToken(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = b64url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const claims = b64url(JSON.stringify({
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/androidpublisher",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  }));
  const pem = sa.private_key.replace(/-----[^-]+-----/g, "").replace(/\s+/g, "");
  const der = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0));
  const key = await crypto.subtle.importKey(
    "pkcs8",
    der,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(`${header}.${claims}`),
  );
  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: `${header}.${claims}.${b64url(signature)}`,
    }),
  });
  if (!res.ok) throw new Error(`Google token request failed (${res.status})`);
  return (await res.json()).access_token as string;
}

const ACTIVE = new Set(["SUBSCRIPTION_STATE_ACTIVE", "SUBSCRIPTION_STATE_IN_GRACE_PERIOD"]);

Deno.serve(async (req) => {
  if (req.method !== "POST") return error("Method not allowed", 405);

  const user = await getCaller(userClient(req));
  if (!user) return error("Not signed in", 401);

  let body: { platform?: unknown; productId?: unknown; purchaseToken?: unknown };
  try {
    body = await req.json();
  } catch {
    return error("Body must be JSON", 400);
  }
  if (body.platform !== "android") {
    return error("Only Google Play purchases can be verified at the moment.", 501);
  }
  if (typeof body.purchaseToken !== "string" || typeof body.productId !== "string") {
    return error("productId and purchaseToken are required", 400);
  }

  const pkg = Deno.env.get("GOOGLE_PLAY_PACKAGE_NAME");
  const saJson = Deno.env.get("GOOGLE_PLAY_SERVICE_ACCOUNT_JSON");
  if (!pkg || !saJson) return error("Purchases are not set up on the server yet.", 503);

  let sub: {
    subscriptionState?: string;
    lineItems?: { productId?: string; expiryTime?: string }[];
  };
  try {
    const token = await googleAccessToken(JSON.parse(saJson) as ServiceAccount);
    const url =
      `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${encodeURIComponent(pkg)}` +
      `/purchases/subscriptionsv2/tokens/${encodeURIComponent(body.purchaseToken)}`;
    const res = await fetch(url, { headers: { Authorization: `Bearer ${token}` } });
    if (res.status === 404 || res.status === 400) return error("This purchase was not found.", 404);
    if (!res.ok) throw new Error(`Play API ${res.status}`);
    sub = await res.json();
  } catch (e) {
    console.error("verify-purchase:", e instanceof Error ? e.message : e);
    return error("Could not verify the purchase right now. Please try again.", 502);
  }

  const item = sub.lineItems?.find((l) => l.productId === body.productId) ?? sub.lineItems?.[0];
  const active = ACTIVE.has(sub.subscriptionState ?? "");
  const until = item?.expiryTime ?? null;

  const { error: writeError } = await adminClient()
    .from("profiles")
    .update({
      is_premium: active,
      premium_until: until,
      premium_product: item?.productId ?? body.productId,
    })
    .eq("id", user.id);
  if (writeError) return error("Could not save the subscription.", 500);

  return json({ premium: active, until });
});
