#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BENCHMARK_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TARGET_ROOT="$BENCHMARK_ROOT/repo-target"
TARGET_SHA="4c751c503bc753095f4b4f052e106f95218cc33f"
DEPWIRE_VERSION="1.15.0"

usage() {
  echo "Usage: $0 <1|2|3>" >&2
  exit 2
}

candidate="${1:-}"
case "$candidate" in
  1)
    symbol="ModuleMetadata.imports"
    changed_file="packages/common/interfaces/modules/module-metadata.interface.ts"
    identifiers=(ModuleMetadata imports)
    ;;
  2)
    symbol="FactoryProvider.inject"
    changed_file="packages/common/interfaces/modules/provider.interface.ts"
    identifiers=(FactoryProvider inject)
    ;;
  3)
    symbol="ClassProvider.scope"
    changed_file="packages/common/interfaces/modules/provider.interface.ts"
    identifiers=(ClassProvider scope)
    ;;
  *) usage ;;
esac

test -d "$TARGET_ROOT/.git" || {
  echo "ERROR: missing fallback target repository: $TARGET_ROOT" >&2
  exit 1
}

actual_sha="$(git -C "$TARGET_ROOT" rev-parse HEAD)"
test "$actual_sha" = "$TARGET_SHA" || {
  echo "ERROR: expected target SHA $TARGET_SHA, found $actual_sha" >&2
  exit 1
}

if test -n "$(git -C "$TARGET_ROOT" status --porcelain --untracked-files=no)"; then
  echo "ERROR: target repository has tracked changes before verification" >&2
  git -C "$TARGET_ROOT" status --short >&2
  exit 1
fi

work_dir="$(mktemp -d "${TMPDIR:-/tmp}/task-d-candidate-${candidate}.XXXXXX")"
restore() {
  git -C "$TARGET_ROOT" checkout -- "$changed_file" 2>/dev/null || true
  rm -rf "$work_dir"
}
trap restore EXIT INT TERM

cd "$TARGET_ROOT"
case "$candidate" in
  1)
    git apply --unidiff-zero <<'PATCH'
diff --git a/packages/common/interfaces/modules/module-metadata.interface.ts b/packages/common/interfaces/modules/module-metadata.interface.ts
--- a/packages/common/interfaces/modules/module-metadata.interface.ts
+++ b/packages/common/interfaces/modules/module-metadata.interface.ts
@@ -19 +19 @@
-  imports?: Array<
+  imports: Array<
PATCH
    ;;
  2)
    git apply --unidiff-zero <<'PATCH'
diff --git a/packages/common/interfaces/modules/provider.interface.ts b/packages/common/interfaces/modules/provider.interface.ts
--- a/packages/common/interfaces/modules/provider.interface.ts
+++ b/packages/common/interfaces/modules/provider.interface.ts
@@ -128 +128 @@
-  inject?: Array<InjectionToken | OptionalFactoryDependency>;
+  inject: Array<InjectionToken | OptionalFactoryDependency>;
PATCH
    ;;
  3)
    git apply --unidiff-zero <<'PATCH'
diff --git a/packages/common/interfaces/modules/provider.interface.ts b/packages/common/interfaces/modules/provider.interface.ts
--- a/packages/common/interfaces/modules/provider.interface.ts
+++ b/packages/common/interfaces/modules/provider.interface.ts
@@ -48 +48 @@
-  scope?: Scope;
+  scope: Scope;
PATCH
    ;;
esac

set +e
npx tsc -b packages --pretty false --force >"$work_dir/typecheck.log" 2>&1
typecheck_status=$?
set -e
if test "$typecheck_status" -eq 0; then
  echo "ERROR: candidate $candidate produced no type errors" >&2
  exit 1
fi

sed -nE 's#^([^ (]+\.(ts|tsx|mts|cts))\([0-9]+,[0-9]+\): error.*#\1#p' \
  "$work_dir/typecheck.log" | sort -u >"$work_dir/oracle.txt"
oracle_size="$(wc -l <"$work_dir/oracle.txt" | tr -d ' ')"
test "$oracle_size" -gt 0 || {
  echo "ERROR: typecheck failed but no TypeScript error files were parsed" >&2
  cat "$work_dir/typecheck.log" >&2
  exit 1
}

: >"$work_dir/grep-union.txt"
for identifier in "${identifiers[@]}"; do
  rg -l -w --no-ignore --hidden "$identifier" . \
    -g '!.git/**' -g '!node_modules/**' -g '!**/node_modules/**' \
    -g '!dist/**' -g '!**/dist/**' -g '!.depwire/**' \
    -g '!depwire-output.json' -g '!coverage/**' -g '!**/coverage/**' \
    | sed 's#^\./##' >>"$work_dir/grep-union.txt" || true
done
sort -u -o "$work_dir/grep-union.txt" "$work_dir/grep-union.txt"
grep_size="$(wc -l <"$work_dir/grep-union.txt" | tr -d ' ')"

comm -23 "$work_dir/oracle.txt" "$work_dir/grep-union.txt" \
  >"$work_dir/unreachable.txt"
unreachable_size="$(wc -l <"$work_dir/unreachable.txt" | tr -d ' ')"

npx -y "depwire-cli@$DEPWIRE_VERSION" affected "$changed_file" --depth 10 --json \
  >"$work_dir/depwire.log" 2>&1
sed -nE 's/^[[:space:]]*"filePath": "([^"]+)",$/\1/p' "$work_dir/depwire.log" \
  | sort -u >"$work_dir/depwire-files.txt"
comm -12 "$work_dir/oracle.txt" "$work_dir/depwire-files.txt" \
  >"$work_dir/depwire-found.txt"
comm -23 "$work_dir/oracle.txt" "$work_dir/depwire-files.txt" \
  >"$work_dir/depwire-missed.txt"
depwire_found="$(wc -l <"$work_dir/depwire-found.txt" | tr -d ' ')"
depwire_missed="$(wc -l <"$work_dir/depwire-missed.txt" | tr -d ' ')"

awk -F/ '$1 == "packages" && $2 != "common" { print }' "$work_dir/oracle.txt" \
  >"$work_dir/cross-package.txt"
cross_package_size="$(wc -l <"$work_dir/cross-package.txt" | tr -d ' ')"

echo "Candidate: $candidate"
echo "Symbol: $symbol"
echo "Changed file: $changed_file"
echo "Prompt identifiers: ${identifiers[*]}"
echo "Typecheck command: npx tsc -b packages --pretty false --force"
echo "Typecheck exit: $typecheck_status"
echo "Oracle size: $oracle_size"
echo "Grep union size: $grep_size"
echo "Gate 1 unreachable: $unreachable_size of $oracle_size"
echo "Gate 2 cross-package: $cross_package_size of $oracle_size"
echo "Gate 3 Depwire recall: $depwire_found found / $depwire_missed missed"
echo "Oracle files:"
sed 's/^/  /' "$work_dir/oracle.txt"
echo "Unreachable oracle files:"
sed 's/^/  /' "$work_dir/unreachable.txt"
echo "Cross-package oracle counts:"
awk -F/ '$1 == "packages" && $2 != "common" { count[$2]++ } END { for (p in count) print p, count[p] }' \
  "$work_dir/oracle.txt" | sort | sed 's/^/  /'
echo "Depwire missed oracle files:"
sed 's/^/  /' "$work_dir/depwire-missed.txt"
