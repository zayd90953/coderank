/** @type {import('jest').Config} */
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  roots: ['<rootDir>/src'],
  testMatch: ['**/*.test.ts'],
  clearMocks: true,
  verbose: true,
  // Route the Admin/Functions SDK entry points to lightweight mocks so unit
  // tests never load the real SDKs (whose transitive `jose` dependency is
  // ESM-only and un-requireable under Jest here). Production code paths are
  // unchanged — this mapping applies to the Jest runtime only.
  moduleNameMapper: {
    '^firebase-functions/v2/https$': '<rootDir>/__mocks__/firebase-functions/v2/https.ts',
    '^firebase-admin/app$': '<rootDir>/__mocks__/firebase-admin/app.ts',
    '^firebase-admin/firestore$': '<rootDir>/__mocks__/firebase-admin/firestore.ts',
  },
};
