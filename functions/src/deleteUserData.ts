/**
 * `deleteUserData` — Firebase Callable Function v2.
 *
 * Store-review requirement: a signed-in user can erase their account and all
 * server-side data in one step. The client calls this BEFORE deleting the
 * Firebase Auth record — after `user.delete()` the callable could no longer
 * authenticate.
 *
 * Wipes, in order:
 *   1. Every document under `users/{uid}` (recursive, batched, re-querying
 *      until empty so trees of any size complete).
 *   2. The user's refresh tokens (revoked sessions die immediately).
 *   3. The Firebase Auth record itself — email/password AND any linked
 *      Google credential go with it.
 *
 * Self-service only: `auth.uid` comes from the verified callable context and
 * is the ONLY uid that may be wiped. No payload fields are trusted.
 */

import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { initializeApp, getApps } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { getAuth } from 'firebase-admin/auth';

import { USERS_COLLECTION } from './constants';

/** Firestore batch size (Firebase-recommended cap for bulk deletes). */
export const PAGE_SIZE = 200;

/** Narrow structural interface so unit tests can inject fakes. */
export interface DeleteDeps {
  deleteSubtree: (rootDocPath: string) => Promise<void>;
  revokeRefreshTokens: (uid: string) => Promise<void>;
  deleteUser: (uid: string) => Promise<void>;
}

/** Core handler (dependency-injected; the callable delegates to this). */
export async function handleDeleteUserData(
  auth: { uid: string } | undefined,
  deps: DeleteDeps,
): Promise<{ success: boolean }> {
  if (!auth || typeof auth.uid !== 'string' || auth.uid.length === 0) {
    throw new HttpsError('unauthenticated', 'Sign in to delete your account.');
  }
  const uid = auth.uid;

  // 1 ── Wipe the whole user tree: profile/progress/weakAreas/sessions/
  //      syncMetadata and anything else that may accumulate under users/{uid}.
  await deps.deleteSubtree(`${USERS_COLLECTION}/${uid}`);

  // 2 ── Revoke refresh tokens so every OTHER signed-in device is logged
  //      out at its next token refresh.
  await deps.revokeRefreshTokens(uid);

  // 3 ── Delete the Auth record LAST: this callable authenticated with that
  //      account's ID token, and the wipe is irreversible — doing it last
  //      guarantees a failed wipe can be retried by an authenticated caller.
  await deps.deleteUser(uid);

  return { success: true };
}

/** The deployed callable. */
export const deleteUserData = onCall(async (request) => {
  if (getApps().length === 0) initializeApp();
  const db = getFirestore();

  return handleDeleteUserData(request.auth ?? undefined, {
    deleteSubtree: (root) => deleteDocTree(db, root),
    revokeRefreshTokens: (uid) => getAuth().revokeRefreshTokens(uid),
    deleteUser: (uid) => getAuth().deleteUser(uid),
  });
});

// ── Admin plumbing (standard recursive-delete pattern) ────────────────────

/** Deletes a document, its subcollections, and everything beneath them. */
async function deleteDocTree(
  db: ReturnType<typeof getFirestore>,
  docPath: string,
): Promise<void> {
  const [colPath, docId] = splitDocPath(docPath);
  const docRef = db.collection(colPath).doc(docId);

  for (const sub of await docRef.listCollections()) {
    await deleteCollection(db, `${docPath}/${sub.id}`);
  }
  await docRef.delete();
}

/** Deletes every document of a collection, re-querying until empty. */
async function deleteCollection(
  db: ReturnType<typeof getFirestore>,
  collectionPath: string,
): Promise<void> {
  for (;;) {
    const snap = await db.collection(collectionPath).limit(PAGE_SIZE).get();
    if (snap.empty) return;

    const batch = db.batch();
    for (const doc of snap.docs) {
      await deleteDocTree(db, doc.ref.path); // nested subtrees go first
      batch.delete(doc.ref);
    }
    await batch.commit();
  }
}

/** Splits "users/abc/sessions/xyz" into ("users/abc/sessions", "xyz"). */
function splitDocPath(path: string): [string, string] {
  const segments = path.split('/');
  if (segments.length < 2 || segments.length % 2 !== 0) {
    throw new Error(`Invalid document path: ${path}`);
  }
  const docId = segments.pop()!;
  return [segments.join('/'), docId];
}
