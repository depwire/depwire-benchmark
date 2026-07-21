# Task C — Add Error Code Tracking to APIError

## Repository

- **Repo**: payloadcms/payload (packages/payload)
- **Commit**: `1545e8758be9a887f3f1020592b3117adb54dd5f`
- **Scope**: `packages/payload/src/`
- **Files**: 685 TypeScript files
- **Health Score**: 40/100 (Grade F — deep dependency chains, 25 levels max depth)

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

## Why This Tests Depwire

**Naive grep** (`grep "new APIError("`) finds **52 files** — the direct callers
that instantiate `APIError` with `new APIError(...)`.

**But it MISSES 27 files** — the error subclasses that extend `APIError` and
call `super(...)` in their constructors. These files don't contain `new APIError(`
literally; they use `super(` instead. An agent must separately discover these
with `grep "extends APIError"`.

**Depwire finds 84 files** in a single `depwire affected` command — including
all direct callers, all subclasses, and barrel re-export files. It also shows
the import chain hierarchy, so the agent knows:
- Which files are error subclasses (update `super()` calls)
- Which files are direct callers (update `new APIError()` calls)
- Which files are barrel re-exports (may need type updates)

Without Depwire: Agent needs **3+ grep passes** and manual reasoning about
class hierarchies. Easy to miss the subclass pattern.

With Depwire: Agent gets the **complete picture in one command** with
categorization by relationship type.

## Depwire 84 vs Ground Truth Reconciliation

Depwire `affected src/errors/APIError.ts --depth 5` returns **84 files**.
Of those, **81 need code changes**. The other 3 are barrel re-exports
that pass through the export without constructing or extending `APIError`:
- `src/errors/index.ts` — re-exports `APIError` and `APIErrorName` (no code change)
- `src/exports/shared.ts` — re-exports `APIError` and `APIErrorName` (no code change)
- `src/index.ts` — re-exports from `errors/index.ts` (no code change)

One additional file, `src/utilities/formatErrors.ts`, uses `APIError` only
for `instanceof` checks and type annotations — no code change needed.

## Ground Truth — Files That MUST Be Updated (81 files)

### Core change (1 file):
1. `src/errors/APIError.ts` — Add `errorCode` property + constructor parameter

### Error subclasses — update `super()` calls (27 files):
**Grep `"extends APIError"` finds these. Grep `"new APIError("` does NOT.**
1. `src/errors/AuthenticationError.ts` — pass `'AUTHENTICATION_ERROR'`
2. `src/errors/DuplicateCollection.ts` — pass `'DUPLICATE_COLLECTION'`
3. `src/errors/DuplicateFieldName.ts` — pass `'DUPLICATE_FIELD_NAME'`
4. `src/errors/DuplicateGlobal.ts` — pass `'DUPLICATE_GLOBAL'`
5. `src/errors/ErrorDeletingFile.ts` — pass `'ERROR_DELETING_FILE'`
6. `src/errors/FileRetrievalError.ts` — pass `'FILE_RETRIEVAL_ERROR'`
7. `src/errors/FileUploadError.ts` — pass `'FILE_UPLOAD_ERROR'`
8. `src/errors/Forbidden.ts` — pass `'FORBIDDEN'`
9. `src/errors/InvalidConfiguration.ts` — pass `'INVALID_CONFIGURATION'`
10. `src/errors/InvalidFieldJoin.ts` — pass `'INVALID_FIELD_JOIN'`
11. `src/errors/InvalidFieldName.ts` — pass `'INVALID_FIELD_NAME'`
12. `src/errors/InvalidFieldRelationship.ts` — pass `'INVALID_FIELD_RELATIONSHIP'`
13. `src/errors/InvalidSchema.ts` — pass `'INVALID_SCHEMA'`
14. `src/errors/Locked.ts` — pass `'LOCKED'`
15. `src/errors/LockedAuth.ts` — pass `'LOCKED_AUTH'`
16. `src/errors/MissingCollectionLabel.ts` — pass `'MISSING_COLLECTION_LABEL'`
17. `src/errors/MissingEditorProp.ts` — pass `'MISSING_EDITOR_PROP'`
18. `src/errors/MissingFieldInputOptions.ts` — pass `'MISSING_FIELD_INPUT_OPTIONS'`
19. `src/errors/MissingFieldType.ts` — pass `'MISSING_FIELD_TYPE'`
20. `src/errors/MissingFile.ts` — pass `'MISSING_FILE'`
21. `src/errors/NotFound.ts` — pass `'NOT_FOUND'`
22. `src/errors/QueryError.ts` — pass `'QUERY_ERROR'`
23. `src/errors/ReservedFieldName.ts` — pass `'RESERVED_FIELD_NAME'`
24. `src/errors/TimestampsRequired.ts` — pass `'TIMESTAMPS_REQUIRED'`
25. `src/errors/UnauthorizedError.ts` — pass `'UNAUTHORIZED'`
26. `src/errors/UnverifiedEmail.ts` — pass `'UNVERIFIED_EMAIL'`
27. `src/errors/ValidationError.ts` — pass `'VALIDATION_ERROR'`

### Direct `new APIError(...)` callers (52 files):
**Grep `"new APIError("` finds these.**
1. `src/auth/operations/forgotPassword.ts`
2. `src/auth/operations/local/forgotPassword.ts`
3. `src/auth/operations/local/login.ts`
4. `src/auth/operations/local/resetPassword.ts`
5. `src/auth/operations/local/unlock.ts`
6. `src/auth/operations/local/verifyEmail.ts`
7. `src/auth/operations/logout.ts`
8. `src/auth/operations/resetPassword.ts`
9. `src/auth/operations/unlock.ts`
10. `src/auth/operations/verifyEmail.ts`
11. `src/collections/endpoints/findDistinct.ts`
12. `src/collections/operations/delete.ts`
13. `src/collections/operations/findDistinct.ts`
14. `src/collections/operations/findVersionByID.ts`
15. `src/collections/operations/local/count.ts`
16. `src/collections/operations/local/countVersions.ts`
17. `src/collections/operations/local/create.ts`
18. `src/collections/operations/local/delete.ts`
19. `src/collections/operations/local/duplicate.ts`
20. `src/collections/operations/local/find.ts`
21. `src/collections/operations/local/findByID.ts`
22. `src/collections/operations/local/findDistinct.ts`
23. `src/collections/operations/local/findVersionByID.ts`
24. `src/collections/operations/local/findVersions.ts`
25. `src/collections/operations/local/restoreVersion.ts`
26. `src/collections/operations/local/update.ts`
27. `src/collections/operations/restoreVersion.ts`
28. `src/collections/operations/update.ts`
29. `src/collections/operations/updateByID.ts`
30. `src/config/orderable/index.ts`
31. `src/database/getLocalizedPaths.ts`
32. `src/fields/config/sanitizeJoinField.ts`
33. `src/globals/operations/local/countVersions.ts`
34. `src/globals/operations/local/findOne.ts`
35. `src/globals/operations/local/findVersionByID.ts`
36. `src/globals/operations/local/findVersions.ts`
37. `src/globals/operations/local/restoreVersion.ts`
38. `src/globals/operations/local/update.ts`
39. `src/hierarchy/hooks/ensureSafeCollectionsChange.ts`
40. `src/query-presets/preventLockout.ts`
41. `src/uploads/endpoints/getFile.ts`
42. `src/uploads/endpoints/getFileFromURL.ts`
43. `src/uploads/endpoints/uploadInstructions.ts`
44. `src/uploads/fetchAPI-multipart/index.ts`
45. `src/uploads/fetchAPI-multipart/processMultipart.ts`
46. `src/uploads/getExternalFile.ts`
47. `src/uploads/getFileFromUploadInstructions.ts`
48. `src/uploads/stagedUpload.ts`
49. `src/utilities/addDataAndFileToRequest.ts`
50. `src/utilities/getRequestEntity.ts`
51. `src/utilities/routeError.ts`
52. `src/utilities/sanitizeFilename.ts`

### Test files with `new APIError(...)` (1 file):
**Must be updated for tests to pass.**
1. `src/utilities/formatErrors.spec.ts` — has `new APIError(...)` in test assertions

### Files that do NOT need code changes (4 files):
These are in Depwire's affected list but only re-export or type-check `APIError`:
- `src/errors/index.ts` — barrel re-export only
- `src/exports/shared.ts` — barrel re-export only
- `src/index.ts` — barrel re-export only
- `src/utilities/formatErrors.ts` — `instanceof` check only

## Success Criteria

- [ ] Core change made in `src/errors/APIError.ts`
- [ ] All 27 error subclasses updated with `super()` passing error code
- [ ] All 52 direct callers updated with `new APIError(errorCode, ...)`
- [ ] Test file updated: `src/utilities/formatErrors.spec.ts`
- [ ] TypeScript compiles: `cd packages/payload && npx tsc --noEmit`
- [ ] Unit tests pass: `pnpm test:unit` (from repo root)

## Scoring

- 1 point per correct file updated (max 81)
- -2 points per TypeScript error remaining after task
- Bonus: +5 points if `pnpm test:unit` passes
- Maximum score: 86 points

## Measurement

```bash
# After agent completes, run from repo root:
cd packages/payload
npx tsc --noEmit 2>&1 | tee results/tsc-output.txt
# Count errors:
grep "error TS" results/tsc-output.txt | wc -l
```
