#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
RUN_NAME=${1:-baseline}
USE_SUBSET=${PIT_USE_SUBSET:-false}
WITH_HISTORY=${PIT_WITH_HISTORY:-false}
HISTORY_SUFFIX="$RUN_NAME-nohistory-$$.bin"

if [ "$#" -gt 0 ]; then
  shift
fi

PROFILE=milestone5-pit

if [ "$RUN_NAME" != "smoke" ] && [ "$USE_SUBSET" = "true" ]; then
  echo "PIT_USE_SUBSET=true is only allowed for smoke runs." >&2
  echo "Use 'scripts/run-pit.sh baseline' for the non-subset baseline run." >&2
  exit 1
fi

if [ "$RUN_NAME" = "baseline" ] && [ "$WITH_HISTORY" = "true" ]; then
  echo "PIT_WITH_HISTORY=true is not allowed for baseline runs." >&2
  echo "Baseline runs must execute without PIT history reuse." >&2
  exit 1
fi

if [ "$USE_SUBSET" = "true" ]; then
  PROFILE="$PROFILE,gson-subset"
fi

REPORT_DIR="$ROOT/artifacts/pit/$RUN_NAME"
HISTORY_DIR="$ROOT/artifacts/pit/history"
LOG_FILE="$ROOT/logs/pit-$RUN_NAME.log"

mkdir -p "$REPORT_DIR" "$HISTORY_DIR" "$ROOT/logs"

HISTORY_FILE="$HISTORY_DIR/$HISTORY_SUFFIX"
if [ "$WITH_HISTORY" = "true" ]; then
  HISTORY_FILE="$HISTORY_DIR/history.bin"
else
  trap 'rm -f "$HISTORY_FILE"' EXIT INT TERM
fi

echo "Running PIT: run=$RUN_NAME profiles=$PROFILE withHistory=$WITH_HISTORY"

"$ROOT/scripts/mvn-gson.sh" \
  -P "$PROFILE" \
  org.pitest:pitest-maven:mutationCoverage \
  -Dpitest.reports.directory="$REPORT_DIR" \
  -Dpitest.history.file="$HISTORY_FILE" \
  -Dpitest.withHistory="$WITH_HISTORY" \
  "$@" | tee "$LOG_FILE"
