#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
GSON_MODULE="$ROOT/gson/gson"
JAVA_HOME=$(/usr/libexec/java_home -v 21)

export JAVA_HOME
export PATH="$JAVA_HOME/bin:$PATH"

cd "$GSON_MODULE"
exec mvn -Dmaven.repo.local="$ROOT/.m2" "$@"
