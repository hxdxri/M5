#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
PATCH_FILE="$ROOT/patches/gson-milestone5.patch"

if [ -z "$(git -C "$ROOT/gson" diff --name-only)" ]; then
  echo "No local changes in the gson submodule to export." >&2
  exit 1
fi

git -C "$ROOT/gson" diff > "$PATCH_FILE"
echo "Updated $PATCH_FILE"
