// POST → { deleted: true }
// Permanently deletes the caller's account. The profile, birth profile,
// chart, homes, rooms and furniture are removed by ON DELETE CASCADE.
import { adminClient, error, getCaller, json, userClient } from "../_shared/http.ts";

Deno.serve(async (req) => {
  if (req.method !== "POST") return error("Method not allowed", 405);

  // Only the signed-in user can delete their own account.
  const user = await getCaller(userClient(req));
  if (!user) return error("Not signed in", 401);

  const { error: deleteError } = await adminClient().auth.admin.deleteUser(user.id);
  if (deleteError) {
    console.error("delete-account failed", deleteError.message);
    return error("Could not delete the account. Please try again.", 500);
  }
  return json({ deleted: true });
});
