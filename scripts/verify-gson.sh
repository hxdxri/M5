#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)

mkdir -p "$ROOT/logs"

"$ROOT/scripts/mvn-gson.sh" clean test | tee "$ROOT/logs/verify-gson.log"
