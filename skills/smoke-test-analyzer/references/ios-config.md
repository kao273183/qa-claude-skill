# iOS CI Configuration

## Scanning Commands

```bash
# Unit tests
find unionTests -name "*Tests.swift" -type f
# UI tests
find unionUITests -name "*Tests.swift" -type f
# SPM Package tests
find union/Packages -name "*Tests.swift" -path "*/Tests/*" -type f
# Count methods per file
grep -c '@Test\|func test' <file>
```

## Existing Test Plans

Read all `*.xctestplan` files to understand current state:
- `selectedTests` = include list (only these run)
- `skippedTests` = exclude list (everything else runs)
- No list = all tests in target run

Known plans in union-ios:
- `UnitTests.xctestplan` — PR + Daily (all unit, skip `.apiTest`)
- `DailyTests.xctestplan` — unused (all unit, `-DailyTest` flag)
- `UITests.xctestplan` — Daily (all UI, skip SocialUITests)
- `SmokeTests.xctestplan` — unused (only `SmokeUITests`)

## Generating .xctestplan

### Option A: Update existing SmokeTests.xctestplan

Add unit test targets with `selectedTests`:
```json
{
  "defaultOptions": {
    "commandLineArgumentEntries": [
      { "argument": "-SmokeTest" }
    ],
    "defaultTestExecutionTimeAllowance": 120,
    "testTimeoutsEnabled": true
  },
  "testTargets": [
    {
      "selectedTests": ["SmokeUITests"],
      "target": {
        "containerPath": "container:union.xcodeproj",
        "identifier": "B0F6F7982CEB3A6500927E9B",
        "name": "unionUITests"
      }
    },
    {
      "selectedTests": ["IOMConfigurationTests", "IOMCookieTests"],
      "target": {
        "containerPath": "container:union.xcodeproj",
        "identifier": "B0F6F78E2CEB3A6500927E9B",
        "name": "unionTests"
      }
    }
  ],
  "version": 1
}
```

### Option B: Create new DailySmokeTests.xctestplan

Fresh plan with T0+T1 only. Key settings for speed:
- `testTimeoutsEnabled: true` + `defaultTestExecutionTimeAllowance: 120`
- No `codeCoverage` targets (saves ~30% CI time)
- `-SmokeTest` command line argument

## CI Workflow Snippet

```yaml
# In daily-workflow.yml — tiered approach
- name: Run Smoke Tests (T0+T1, fast fail)
  run: |
    xcodebuild test \
      -scheme union \
      -testPlan DailySmokeTests \
      -destination 'platform=iOS Simulator,name=iPhone 16'

- name: Run Full Tests (T2, only if smoke passes)
  if: steps.smoke.outcome == 'success'
  run: |
    xcodebuild test \
      -scheme union \
      -testPlan UnitTests \
      -destination 'platform=iOS Simulator,name=iPhone 16'
```
