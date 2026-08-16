# Task C — Add Error Code Tracking to APIError

## Repository

- **Repo**: payloadcms/payload (packages/payload)
- **Commit**: `1545e8758be9a887f3f1020592b3117adb54dd5f`
- **Scope**: the full pinned `payloadcms/payload` monorepo

## The Change

Add a required `errorCode: string` field to the `APIError` class in
`packages/payload/src/errors/APIError.ts`.

Specifically:
1. Add `errorCode: string` as the **first parameter** of the `APIError` constructor
2. Store it as a public readonly property: `readonly errorCode: string`
3. Every error subclass that extends `APIError` must update its `super()` call
   to pass a specific error code string (e.g., `'FORBIDDEN'`, `'NOT_FOUND'`, etc.)
4. Every direct `new APIError(...)` call site must pass an appropriate error code
   as the first argument

The error code should be an UPPER_SNAKE_CASE string identifying the error type,
such as `'VALIDATION_ERROR'`, `'FORBIDDEN'`, `'NOT_FOUND'`, `'INTERNAL_ERROR'`, etc.

You are responsible for discovering and updating every affected source file in
the monorepo. Do not limit the change to `packages/payload/src/`; packages,
examples, and tests that consume this public constructor are in scope.

## Success Criteria

- [ ] Core change made in `src/errors/APIError.ts`
- [ ] Every affected source consumer in the monorepo uses the new constructor
      contract with an appropriate error code
- [ ] TypeScript compiles: `cd packages/payload && npx tsc --noEmit`
- [ ] Unit tests pass: `pnpm test:unit` (from repo root)
