# M5
CMPT 470 Milestone 5 workspace for Tech Titans on the Gson repository.

This workspace now contains:

- the assignment PDFs and prior milestone report at the root
- the upstream `google/gson` repository as a Git submodule in [`gson`](/Users/haidari/Desktop/M5/gson)
- a tracked patch for the Gson PIT changes in [`patches/gson-milestone5.patch`](/Users/haidari/Desktop/M5/patches/gson-milestone5.patch)
- helper scripts in [`scripts`](/Users/haidari/Desktop/M5/scripts)
- setup notes in [`docs/milestone5-foundation.md`](/Users/haidari/Desktop/M5/docs/M5-Foundation.md)

Quick start:

- Initialize the submodule: `git submodule update --init --recursive`
- Reapply the Gson PIT patch after checkout: `scripts/apply-gson-patch.sh`
- Refresh the tracked patch after new Gson edits: `scripts/refresh-gson-patch.sh`
- Local Maven/JDK path: `scripts/verify-gson.sh`
- Local PIT smoke check: `PIT_USE_SUBSET=true scripts/run-pit.sh smoke`
- Docker + Java 17 path: `scripts/verify-gson-docker.sh`
- PIT smoke run in Docker: `PIT_USE_SUBSET=true scripts/run-pit-docker.sh smoke`
- PIT baseline run in Docker: `scripts/run-pit-docker.sh baseline`

Current status:

- The host setup is verified and the PIT smoke run already succeeds.
- The Docker path pins Maven to Java 17 with `maven:3.9.11-eclipse-temurin-17`.
- Start Docker Desktop before using the Docker scripts; the scripts now fail fast if the daemon is not running.

The Docker path is the safest option for the report because it keeps the Java version aligned with the assignment guide.
