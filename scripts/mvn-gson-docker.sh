#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)

mkdir -p "$ROOT/.m2-docker"

if ! docker info >/dev/null 2>&1; then
  echo "Docker is installed but the daemon is not available." >&2
  echo "Start Docker Desktop (or another Docker daemon) and rerun this script." >&2
  exit 1
fi

exec docker run --rm \
  -v "$ROOT":/workspace \
  -v "$ROOT/.m2-docker":/root/.m2 \
  -w /workspace/gson/gson \
  maven:3.9.11-eclipse-temurin-17 \
  mvn -Dmaven.repo.local=/root/.m2 "$@"
