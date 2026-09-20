/**
 * Manual jest mock for `firebase-admin/firestore`.
 *
 * Timestamps/FieldValues become plain sentinel objects the in-memory
 * FakeFirestore (src/__tests__/fakes.ts) knows how to resolve. getFirestore
 * is a stub — tests inject their own DbLike.
 *
 * Auto-applied to all suites (functions/__mocks__ adjacent to node_modules).
 */

export const getFirestore = jest.fn();

export const Timestamp = {
  fromDate: (d: Date) => ({ __sentinel: 'timestamp', iso: d.toISOString() }),
  now: () => ({ __sentinel: 'timestamp', iso: new Date().toISOString() }),
};

export const FieldValue = {
  increment: (n: number) => ({ __sentinel: 'increment', n }),
  serverTimestamp: () => ({ __sentinel: 'serverTimestamp' }),
  delete: () => ({ __sentinel: 'delete' }),
};
