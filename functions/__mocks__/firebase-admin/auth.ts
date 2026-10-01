/**
 * Manual jest mock for `firebase-admin/auth`.
 *
 * Unit tests exercise the dependency-injected `handleDeleteUserData` and
 * never touch the real Admin Auth SDK (whose transitive `jose` dependency
 * is ESM-only and un-requireable under Jest). Like the firestore/app
 * mocks, this exists only for the Jest runtime — never at deploy.
 */

export const getAuth = jest.fn();
