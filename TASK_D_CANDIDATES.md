# Task D candidate measurements

## Reproducibility pin

Repository: `nestjs/nest` (fallback repository; baseline selection Step 4)
Tag: `v12.0.1`
Commit SHA: `4c751c503bc753095f4b4f052e106f95218cc33f`
Install command: `npm ci --legacy-peer-deps`
Install result: exit 0
Install wall time: 69.03 seconds
Build/typecheck command: `npm run build` (`tsc -b -v packages` plus the repository's postbuild)
Build/typecheck result: exit 0
Build/typecheck wall time: 7.34 seconds
Deviation: fallback Step 4 was required; there was no lockfile modification and no relaxed-lockfile install.

Drizzle release-tag attempts preceding the fallback:

- `v1.0.0-rc.4` (`748058e837d9c4247330e3d45580cbdae52bffda`): frozen install succeeded, but `pnpm build` deadlocked in the Bun/rolldown ORM build and was interrupted after 528.44 seconds.
- `v1.0.0-rc.3` (`771c61eb2317337b86827d8c2220b11731958268`): frozen install succeeded; `pnpm build` exited 2 because `integration-tests:test:types` could not resolve `drizzle-seed`, followed by cascading implicit-`any` errors.
- `v1.0.0-rc.1` (`e2a6f87d2752e7276ecbe7a49fc14ba58b0a46cd`): frozen install succeeded; `pnpm build` failed with the same workspace ordering/typecheck error as `rc.3`.
- `v1.0.0-rc.2` (`48e5406027103a9fca6eb66417187c4a8b5c6aa3`): frozen install failed with the original 404 for `drizzle-kit@0.25.0-b1faa33`.

All candidate oracles use `npx tsc -b packages --pretty false --force`, which force-checks all nine package projects in the pinned workspace. Grep unions search the entire working repository (excluding Git metadata, dependencies, generated `dist`/coverage, and Depwire's own cache/output). Depwire measurements use `depwire-cli@1.15.0 affected <changed-file> --depth 10 --json`.

## Comparison

| Candidate | Symbol | Oracle | Grep union | Gate 1: unreachable | Gate 2: cross-package | Gate 3: Depwire found / missed | Chain depth | Gate 1 | Gate 2 |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| 1 | `ModuleMetadata.imports` | 6 | 308 | 3 of 6 | 5 of 6 | 0 / 6 | 5 | PASS | PASS |
| 2 | `FactoryProvider.inject` | 4 | 112 | 3 of 4 | 4 of 4 | 3 / 1 | 4 | PASS | PASS |
| 3 | `ClassProvider.scope` | 3 | 202 | 3 of 3 | 2 of 3 | 3 / 0 | 4 | PASS | PASS |

Depwire recall is a measurement rather than a pass/reject gate in the benchmark instructions; its misses are reported without changing the oracle.

## Candidate 1: require `ModuleMetadata.imports`

- Symbol: `ModuleMetadata.imports`
- Definition: `packages/common/interfaces/modules/module-metadata.interface.ts`
- Package: `@nestjs/common`
- Repository/tag/SHA: `nestjs/nest`, `v12.0.1`, `4c751c503bc753095f4b4f052e106f95218cc33f`
- Prompt identifier set: `ModuleMetadata`, `imports`

Exact proposed change:

```diff
 export interface ModuleMetadata {
-  imports?: Array<
+  imports: Array<
     Type<any> | DynamicModule | Promise<DynamicModule> | ForwardReference
   >;
 }
```

Measurements:

- Oracle: 6 files.
- Grep union: 308 files.
- Gate 1: 3 of 6 oracle files are unreachable by string search — **PASS**.
- Gate 2: 5 of 6 oracle files are outside `@nestjs/common` — **PASS**.
- Gate 3: Depwire found 0 of 6 oracle files and missed 6.

Oracle files:

```text
packages/common/module-utils/configurable-module.builder.ts
packages/core/discovery/discovery-module.ts
packages/core/injector/internal-core-module/internal-core-module.ts
packages/core/router/router-module.ts
packages/microservices/module/clients.module.ts
packages/platform-express/multer/multer.module.ts
```

Gate 1 unreachable files:

```text
packages/core/discovery/discovery-module.ts
packages/core/injector/internal-core-module/internal-core-module.ts
packages/core/router/router-module.ts
```

Gate 2 cross-package counts:

| Package | Oracle files |
|---|---:|
| `@nestjs/core` | 3 |
| `@nestjs/microservices` | 1 |
| `@nestjs/platform-express` | 1 |

Gate 3 missed files:

```text
packages/common/module-utils/configurable-module.builder.ts
packages/core/discovery/discovery-module.ts
packages/core/injector/internal-core-module/internal-core-module.ts
packages/core/router/router-module.ts
packages/microservices/module/clients.module.ts
packages/platform-express/multer/multer.module.ts
```

Worked source-level path (depth 5):

```text
packages/common/interfaces/modules/module-metadata.interface.ts
-> packages/common/interfaces/modules/dynamic-module.interface.ts (extends ModuleMetadata)
-> packages/common/interfaces/modules/index.ts (barrel)
-> packages/common/interfaces/index.ts (barrel)
-> packages/common/index.ts (package barrel)
-> packages/microservices/module/clients.module.ts (workspace import of DynamicModule)
```

The final file returns `DynamicModule` object literals that omit `imports`; neither prompt identifier occurs in three of the other oracle files.

## Candidate 2: require `FactoryProvider.inject`

- Symbol: `FactoryProvider.inject`
- Definition: `packages/common/interfaces/modules/provider.interface.ts`
- Package: `@nestjs/common`
- Repository/tag/SHA: `nestjs/nest`, `v12.0.1`, `4c751c503bc753095f4b4f052e106f95218cc33f`
- Prompt identifier set: `FactoryProvider`, `inject`

Exact proposed change:

```diff
 export interface FactoryProvider<T = any> {
-  inject?: Array<InjectionToken | OptionalFactoryDependency>;
+  inject: Array<InjectionToken | OptionalFactoryDependency>;
 }
```

Measurements:

- Oracle: 4 files.
- Grep union: 112 files.
- Gate 1: 3 of 4 oracle files are unreachable by string search — **PASS**.
- Gate 2: 4 of 4 oracle files are outside `@nestjs/common` — **PASS**.
- Gate 3: Depwire found 3 of 4 oracle files and missed 1.

Oracle files:

```text
packages/core/injector/inquirer/inquirer-providers.ts
packages/core/injector/internal-core-module/internal-core-module-factory.ts
packages/core/router/request/request-providers.ts
packages/platform-express/multer/multer.module.ts
```

Gate 1 unreachable files:

```text
packages/core/injector/inquirer/inquirer-providers.ts
packages/core/injector/internal-core-module/internal-core-module-factory.ts
packages/core/router/request/request-providers.ts
```

Gate 2 cross-package counts:

| Package | Oracle files |
|---|---:|
| `@nestjs/core` | 3 |
| `@nestjs/platform-express` | 1 |

Gate 3 missed files:

```text
packages/core/injector/internal-core-module/internal-core-module-factory.ts
```

Worked source-level path (depth 4):

```text
packages/common/interfaces/modules/provider.interface.ts
-> packages/common/interfaces/modules/index.ts (barrel)
-> packages/common/interfaces/index.ts (barrel)
-> packages/common/index.ts (package barrel)
-> packages/core/injector/inquirer/inquirer-providers.ts (workspace import of Provider)
```

The consumer declares an object as the wider `Provider` union, so it never spells either `FactoryProvider` or `inject` even though its `useFactory` member selects that union branch.

## Candidate 3: require `ClassProvider.scope`

- Symbol: `ClassProvider.scope`
- Definition: `packages/common/interfaces/modules/provider.interface.ts`
- Package: `@nestjs/common`
- Repository/tag/SHA: `nestjs/nest`, `v12.0.1`, `4c751c503bc753095f4b4f052e106f95218cc33f`
- Prompt identifier set: `ClassProvider`, `scope`

Exact proposed change:

```diff
 export interface ClassProvider<T = any> {
-  scope?: Scope;
+  scope: Scope;
 }
```

Measurements:

- Oracle: 3 files.
- Grep union: 202 files.
- Gate 1: 3 of 3 oracle files are unreachable by string search — **PASS**.
- Gate 2: 2 of 3 oracle files are outside `@nestjs/common` — **PASS**.
- Gate 3: Depwire found all 3 oracle files and missed 0.

Oracle and Gate 1 unreachable files (the sets are identical):

```text
packages/common/module-utils/configurable-module.builder.ts
packages/microservices/module/clients.module.ts
packages/platform-express/multer/multer.module.ts
```

Gate 2 cross-package counts:

| Package | Oracle files |
|---|---:|
| `@nestjs/microservices` | 1 |
| `@nestjs/platform-express` | 1 |

Gate 3 missed files: none.

Worked source-level path (depth 4):

```text
packages/common/interfaces/modules/provider.interface.ts
-> packages/common/interfaces/modules/index.ts (barrel)
-> packages/common/interfaces/index.ts (barrel)
-> packages/common/index.ts (package barrel)
-> packages/microservices/module/clients.module.ts (workspace import of Provider)
```

The consumer returns a `Provider`-typed object with `useClass` but no `scope`; it names neither prompt identifier.
