#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
RUN_NAME=${1:-baseline}

if [ "$#" -gt 0 ]; then
  shift
fi

PROFILE=milestone5-pit
if [ "${PIT_USE_SUBSET:-false}" = "true" ]; then
  PROFILE="$PROFILE,gson-subset"
fi

REPORT_DIR="$ROOT/artifacts/pit/$RUN_NAME"
HISTORY_DIR="$ROOT/artifacts/pit/history"
HISTORY_FILE="$HISTORY_DIR/history.bin"
LOG_FILE="$ROOT/logs/pit-$RUN_NAME.log"

mkdir -p "$REPORT_DIR" "$HISTORY_DIR" "$ROOT/logs"

"$ROOT/scripts/mvn-gson.sh" \
  -P "$PROFILE" \
  org.pitest:pitest-maven:mutationCoverage \
  -Dpitest.reports.directory="$REPORT_DIR" \
  -Dpitest.history.file="$HISTORY_FILE" \
  -Dpitest.withHistory="${PIT_WITH_HISTORY:-false}" \
  "$@" | tee "$LOG_FILE"
