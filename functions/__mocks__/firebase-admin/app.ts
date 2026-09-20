/**
 * Manual jest mock for `firebase-admin/app`.
 *
 * Unit tests never initialize a real Firebase app (they inject the
 * in-memory FakeFirestore). This avoids loading the real Admin SDK — and
 * its ESM-only transitive dependencies — inside Jest.
 *
 * Auto-applied to all suites (functions/__mocks__ adjacent to node_modules).
 */

export const initializeApp = jest.fn();
export const getApps = jest.fn(() => []);
export const getApp = jest.fn();
export const deleteApp = jest.fn(async () => undefined);
export const app = jest.fn();
