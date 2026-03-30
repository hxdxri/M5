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
LOG_FILE="$ROOT/logs/pit-$RUN_NAME-docker.log"

mkdir -p "$REPORT_DIR" "$HISTORY_DIR" "$ROOT/logs"

"$ROOT/scripts/mvn-gson-docker.sh" \
  -P "$PROFILE" \
  org.pitest:pitest-maven:mutationCoverage \
  -Dpitest.reports.directory=/workspace/artifacts/pit/"$RUN_NAME" \
  -Dpitest.history.file=/workspace/artifacts/pit/history/history.bin \
  -Dpitest.withHistory="${PIT_WITH_HISTORY:-false}" \
  "$@" | tee "$LOG_FILE"
