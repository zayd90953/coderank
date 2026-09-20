/**
 * In-memory Firestore fake for unit tests — implements the structural
 * DbLike/TxLike interfaces verifySession depends on. No emulator, no
 * network, no production Firestore.
 *
 * FieldValue/Timestamp are jest-mocked (see verifySession.test.ts) into
 * plain sentinel objects this fake can resolve.
 */

import type {
  CollectionRefLike,
  DbLike,
  DocRefLike,
  DocSnapshotLike,
  TxLike,
} from '../verifySession';

export class FakeFirestore implements DbLike {
  /** path → doc data */
  readonly docs = new Map<string, Record<string, unknown>>();
  /** Paths passed to tx.create (asserting which docs were created). */
  readonly createdPaths: string[] = [];

  snap(docPath: string): DocSnapshotLike {
    const data = this.docs.get(docPath);
    const id = docPath.split('/').pop() ?? '';
    return { exists: data !== undefined, id, data: () => data };
  }

  collection(path: string): CollectionRefLike {
    const self = this;
    return {
      doc(id: string): DocRefLike {
        const docPath = `${path}/${id}`;
        return {
          id,
          path: docPath,
          get: async () => self.snap(docPath),
          collection: (sub: string) => self.collection(`${docPath}/${sub}`),
        };
      },
    };
  }

  async getAll(...refs: DocRefLike[]): Promise<DocSnapshotLike[]> {
    return Promise.all(refs.map((r) => r.get()));
  }

  async runTransaction<T>(fn: (tx: TxLike) => Promise<T>): Promise<T> {
    const self = this;
    const tx: TxLike = {
      get: (ref) => ref.get(),
      getAll: (...refs) => self.getAll(...refs),
      create: (ref, data) => {
        if (self.docs.has(ref.path)) {
          throw new Error(`FAKE: tx.create on existing doc ${ref.path}`);
        }
        self.docs.set(ref.path, data);
        self.createdPaths.push(ref.path);
      },
      set: (ref, data, opts) => {
        const existing = self.docs.get(ref.path);
        if (opts?.merge) {
          self.docs.set(ref.path, self.applyMerge(existing ?? {}, data));
        } else {
          self.docs.set(ref.path, { ...data });
        }
      },
    };
    return fn(tx);
  }

  // ── helpers for assertions ────────────────────────────────────────────

  doc(path: string): Record<string, unknown> {
    return this.docs.get(path) ?? {};
  }

  seed(path: string, data: Record<string, unknown>): void {
    this.docs.set(path, data);
  }

  private applyMerge(
    existing: Record<string, unknown>,
    update: Record<string, unknown>,
  ): Record<string, unknown> {
    const merged: Record<string, unknown> = { ...existing };
    for (const [key, value] of Object.entries(update)) {
      merged[key] = this.resolve(existing[key], value);
    }
    return merged;
  }

  private resolve(existing: unknown, value: unknown): unknown {
    if (value && typeof value === 'object') {
      const v = value as Record<string, unknown>;
      if (v['__sentinel'] === 'increment') {
        const base = typeof existing === 'number' ? existing : 0;
        return base + (v['n'] as number);
      }
    }
    return value;
  }
}
