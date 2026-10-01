/**
 * deleteUserData handler unit tests — dependency-injected fakes only.
 * Verifies the security contract and wipe ordering; the recursive-delete
 * plumbing is exercised in deploy smoke checks, not here.
 */

import { HttpsError } from 'firebase-functions/v2/https';

import { handleDeleteUserData } from '../deleteUserData';

describe('handleDeleteUserData', () => {
  const makeDeps = () => {
    const calls: string[] = [];
    return {
      calls,
      deps: {
        deleteSubtree: async (root: string) => {
          calls.push(`subtree:${root}`);
        },
        revokeRefreshTokens: async (uid: string) => {
          calls.push(`revoke:${uid}`);
        },
        deleteUser: async (uid: string) => {
          calls.push(`delete:${uid}`);
        },
      },
    };
  };

  it('rejects unauthenticated callers', async () => {
    const { deps } = makeDeps();
    await expect(handleDeleteUserData(undefined, deps)).rejects.toThrow(
      HttpsError,
    );
  });

  it('wipes subtree → revokes tokens → deletes auth record, in order', async () => {
    const { calls, deps } = makeDeps();
    const res = await handleDeleteUserData({ uid: 'u1' }, deps);
    expect(res).toEqual({ success: true });
    expect(calls).toEqual([
      'subtree:users/u1',
      'revoke:u1',
      'delete:u1',
    ]);
  });

  it('propagates wipe failures so the client can retry', async () => {
    const { deps } = makeDeps();
    const failing = {
      ...deps,
      deleteSubtree: async () => {
        throw new Error('firestore down');
      },
    };
    await expect(
      handleDeleteUserData({ uid: 'u1' }, failing),
    ).rejects.toThrow('firestore down');
  });
});
