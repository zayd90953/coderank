/**
 * Manual jest mock for `firebase-functions/v2/https`.
 *
 * The real module transitively requires the ESM-only `jose` package (via
 * jwks-rsa), which Jest cannot `require` in this environment. Unit tests
 * exercise `handleVerifySession` directly and never need the real HTTPS
 * layer, so this mock provides the two symbols production code uses:
 * `HttpsError` and `onCall`.
 *
 * Placed in functions/__mocks__/ (adjacent to node_modules) so Jest applies
 * it automatically to every test suite. NOT used at runtime/deploy.
 */

export type FunctionsErrorCode =
  | 'ok'
  | 'cancelled'
  | 'unknown'
  | 'invalid-argument'
  | 'deadline-exceeded'
  | 'not-found'
  | 'already-exists'
  | 'permission-denied'
  | 'resource-exhausted'
  | 'failed-precondition'
  | 'aborted'
  | 'out-of-range'
  | 'unimplemented'
  | 'internal'
  | 'unavailable'
  | 'data-loss'
  | 'unauthenticated';

/** Mirrors the real HttpsError surface used by the code under test. */
export class HttpsError extends Error {
  readonly code: FunctionsErrorCode;
  readonly details?: unknown;
  constructor(code: FunctionsErrorCode, message: string, details?: unknown) {
    super(message);
    this.name = 'HttpsError';
    this.code = code;
    this.details = details;
  }
}

/** Passthrough mock — tests never invoke the wrapped callable. */
export const onCall = jest.fn((_opts: unknown, handler: unknown) => handler);

/** onCall's option shape is opaque to the code under test. */
export const Request = {};
