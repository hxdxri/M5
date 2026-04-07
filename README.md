# M5
CMPT 470 Milestone 5 workspace for Tech Titans on the Gson repository.

## Folder structure

```
M5/
├── Tech_Titans_Milestone5_report.pdf   # final report (PDF)
├── Milestone5.pdf                      # assignment description
├── Milestone5_PIT_Guide.pdf            # PIT guide from the assignment
├── TechTitans_Milestone4_AI_Contribution.txt
├── report/                             # latex drafts 
│   ├── main.tex
│   ├── main.pdf
│   └── figures/
├── artifacts/
│   └── pit/                            # PIT mutation-testing results
│       ├── baseline/                   # baseline run (unmodified test suite)
│       ├── experiment3/                # Experiment 3 results
│       ├── experiment5-3added/         # Experiment 5 – 3 tests added
│       ├── experiment5-5removed/       # Experiment 5 – 5 tests removed
│       ├── investigate-*/              # exploratory / investigative runs
│       ├── smoke/                      # quick smoke-check results
│       └── history/                    # incremental-analysis history files
├── logs/                               # console logs from PIT & Maven runs
├── gson/                               # upstream google/gson (Git submodule)
├── patches/
│   └── gson-milestone5.patch           # tracked patch for Gson PIT changes
├── scripts/                            # helper scripts (build, PIT, Docker)
└── docs/                               # working notes and drafts
    └── M5-Foundation.md
```

Quick start:

- Initialize the submodule: `git submodule update --init --recursive`
- Reapply the Gson PIT patch after checkout: `scripts/apply-gson-patch.sh`
- Refresh the tracked patch after new Gson edits: `scripts/refresh-gson-patch.sh`
- Local Maven/JDK path: `scripts/verify-gson.sh`
- Local PIT smoke check: `PIT_USE_SUBSET=true scripts/run-pit.sh smoke`
- Local baseline PIT run: `scripts/run-pit.sh baseline`
- Docker + Java 17 path: `scripts/verify-gson-docker.sh`
- PIT smoke run in Docker: `PIT_USE_SUBSET=true scripts/run-pit-docker.sh smoke`
- PIT baseline run in Docker: `scripts/run-pit-docker.sh baseline`

Baseline safeguards:

- `baseline` runs reject `PIT_USE_SUBSET=true`
- `baseline` runs reject `PIT_WITH_HISTORY=true`
- the PIT runner prints the active `profiles=` and `withHistory=` settings at startup

Current status:

- The host setup is verified and the PIT smoke run already succeeds.
- The Docker path pins Maven to Java 17 with `maven:3.9.11-eclipse-temurin-17`.
- Start Docker Desktop before using the Docker scripts; the scripts now fail fast if the daemon is not running.

The Docker path is the safest option for the report because it keeps the Java version aligned with the assignment guide.
