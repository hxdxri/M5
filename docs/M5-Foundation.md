# Milestone 5 Foundation

## What the Milestone requires

- Use the assigned repository `google/gson` and keep the same analysis scope across all experiments.
- Add PIT to the Maven build, generate both HTML and XML output, and save logs for reproducibility.
- Confirm the test suite is green before running PIT.
- Select a justified subset of the codebase rather than mutating everything.
- Report the repository URL, commit, target scope, approximate LOC, test scope, Java/Maven/OS, and PIT configuration.
- Exclude PIT-incompatible integration tests when they fail the unmutated baseline run.

## What was verified locally

- Repository: `https://github.com/google/gson`
- Checked out commit: `1fa9b7a0a994b006b3be00e2df9de778e71e6807`
- Submodule path for upstream code: [`gson`](/Users/haidari/Desktop/M5/gson)
- Actual module root for the library code inside the submodule: [`gson/gson`](/Users/haidari/Desktop/M5/gson/gson)
- Build system: Maven multi-module; the parent repo root is not the best place to run PIT for this assignment
- Baseline verification from [`gson/gson`](/Users/haidari/Desktop/M5/gson/gson): `mvn clean test`
- Baseline result on this machine: `BUILD SUCCESS`, `4586` tests run, `0` failures, `0` errors, `20` skipped

## Version-control model

- The outer course repo tracks [`gson`](/Users/haidari/Desktop/M5/gson) as a Git submodule pinned to the verified upstream commit.
- The milestone-specific Gson change is stored as [`patches/gson-milestone5.patch`](/Users/haidari/Desktop/M5/patches/gson-milestone5.patch), not as a committed fork of the whole upstream repository.
- Apply the patch after cloning with `git submodule update --init --recursive` followed by `scripts/apply-gson-patch.sh`.
- If the team makes more local edits inside the Gson submodule, refresh the tracked patch with `scripts/refresh-gson-patch.sh`.
- This keeps the class repo small and makes it obvious which upstream version and which local mutation-testing change set were used.

## Java choice

- Gson currently builds with JDKs in the range `17 <= JDK < 22`.
- The host machine has Java 21 available, which works and already passed the baseline build.
- The assignment guide is written around Java 17, so the Docker scripts pin the environment to Maven + Temurin 17 for report-friendly reproducibility.
- The pinned Docker image is `maven:3.9.11-eclipse-temurin-17`.
- In this workspace the Docker scripts are ready.

## Initial PIT scope

- `targetClasses`
- `com.google.gson.stream.*`
- `com.google.gson.JsonStreamParser`
- `targetTests`
- `com.google.gson.*`

Why this scope:

- It is a coherent feature-based slice: Gson's streaming reader/writer/parser subsystem.
- It contains real control flow and boundary handling rather than trivial data holders.
- It has dedicated tests in [`gson/gson/src/test/java/com/google/gson/stream`](/Users/haidari/Desktop/M5/gson/gson/src/test/java/com/google/gson/stream), plus broader functional coverage such as [`gson/gson/src/test/java/com/google/gson/functional/ReadersWritersTest.java`](/Users/haidari/Desktop/M5/gson/gson/src/test/java/com/google/gson/functional/ReadersWritersTest.java), [`gson/gson/src/test/java/com/google/gson/functional/StreamingTypeAdaptersTest.java`](/Users/haidari/Desktop/M5/gson/gson/src/test/java/com/google/gson/functional/StreamingTypeAdaptersTest.java), and [`gson/gson/src/test/java/com/google/gson/functional/LeniencyTest.java`](/Users/haidari/Desktop/M5/gson/gson/src/test/java/com/google/gson/functional/LeniencyTest.java).
- The scope is large enough to be meaningful without defaulting to the whole repository.

Approximate size:

- Target production LOC: about `3038` lines
- Streaming package: `2913` LOC
- `JsonStreamParser`: `125` LOC
- Library module tests available to PIT with `targetTests = com.google.gson.*`: `118` test classes and `4586` executed tests in the baseline Maven run

Initial hypothesis:

- Expect a medium-to-high mutation score because the streaming subsystem has dense unit coverage.
- Expect some surviving mutants around leniency handling, parser edge cases, and weak assertions on exception text or indirect behavior.

## Verified PIT smoke result

- Command: `PIT_USE_SUBSET=true scripts/run-pit.sh smoke`
- Result: `BUILD SUCCESS`
- Duration: about `60` seconds
- Mutations generated: `687`
- Mutations killed: `578` (`84%`)
- Test strength: `86%`
- Line coverage for mutated classes: `959/982` (`98%`)
- Mutations with no coverage: `11`
- Tests executed during mutation analysis: `12665`

Interpretation:

- The PIT configuration is working end to end on the chosen scope.
- The selected streaming slice is strong enough for the milestone and already produces useful surviving mutants to analyze later.

## Repository organization

- [`gson`](/Users/haidari/Desktop/M5/gson): upstream repository as a pinned submodule
- [`patches`](/Users/haidari/Desktop/M5/patches): tracked modifications to apply on top of the pinned upstream commit
- [`docs`](/Users/haidari/Desktop/M5/docs): milestone-specific notes
- [`scripts`](/Users/haidari/Desktop/M5/scripts): repeatable local and Docker runners
- `logs/`: command logs created by the helper scripts
- `artifacts/pit/`: smoke, baseline, and later experiment reports

## Script usage

- Submodule init: `git submodule update --init --recursive`
- Apply Gson patch: `scripts/apply-gson-patch.sh`
- Refresh tracked Gson patch: `scripts/refresh-gson-patch.sh`
- Local host verification: `scripts/verify-gson.sh`
- Local smoke PIT run: `PIT_USE_SUBSET=true scripts/run-pit.sh smoke`
- Local baseline PIT run: `scripts/run-pit.sh baseline`
- Docker verification with Java 17: `scripts/verify-gson-docker.sh`
- Smoke PIT run: `PIT_USE_SUBSET=true scripts/run-pit-docker.sh smoke`
- Baseline PIT run: `scripts/run-pit-docker.sh baseline`
- Later re-runs with PIT history enabled: `PIT_WITH_HISTORY=true scripts/run-pit-docker.sh add-tests`

Current PIT-specific note:

- [`gson/gson/src/test/java/com/google/gson/integration/OSGiManifestIT.java`](/Users/haidari/Desktop/M5/gson/gson/src/test/java/com/google/gson/integration/OSGiManifestIT.java) is excluded from PIT because it is an integration test that expects the final packaged JAR and fails during PIT's pre-mutation baseline phase.

Important note:

- The optional `gson-subset` Maven profile is useful for a fast smoke check only.
- Baseline runs must not use `gson-subset` or `PIT_WITH_HISTORY=true`; the runner scripts now reject both cases explicitly.
- Non-history PIT runs now use a fresh throwaway history file, so a previous smoke run cannot accidentally make `baseline` look artificially fast.
- If you previously exported `PIT_USE_SUBSET` or `PIT_WITH_HISTORY` in your shell, either unset them or run the commands in a fresh shell.
