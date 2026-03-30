#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
PATCH_FILE="$ROOT/patches/gson-milestone5.patch"
EXPECTED_COMMIT="1fa9b7a0a994b006b3be00e2df9de778e71e6807"

if [ "$(git -C "$ROOT/gson" rev-parse HEAD)" != "$EXPECTED_COMMIT" ]; then
  echo "Unexpected gson submodule commit. Expected $EXPECTED_COMMIT." >&2
  exit 1
fi

if git -C "$ROOT/gson" apply --check "$PATCH_FILE" >/dev/null 2>&1; then
  git -C "$ROOT/gson" apply "$PATCH_FILE"
  exit 0
fi

if git -C "$ROOT/gson" apply -R --check "$PATCH_FILE" >/dev/null 2>&1; then
  echo "Patch is already applied to the gson submodule."
  exit 0
fi

echo "Patch could not be applied cleanly. Check the gson submodule state." >&2
exit 1
