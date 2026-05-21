# Android CI Configuration

## Scanning Commands

```bash
# Unit tests
find app/src/test -name "*Test.kt" -type f
# Instrumented / UI tests
find app/src/androidTest -name "*Test.kt" -type f
# Count methods per file
grep -c '@Test' <file>
```

## Existing CI Configuration

Check these locations:
- `build.gradle` / `build.gradle.kts` — test tasks, filters
- `.github/workflows/` — CI workflow files for test commands
- `@RunWith(Suite::class)` — existing test suites
- Custom Gradle tasks for test subsets

## Generating Smoke Configuration

Three options, from least to most invasive:

### Option A: Gradle task with filter (no code changes)

```groovy
// build.gradle
tasks.register("smokeTest", Test::class) {
    useJUnitPlatform()
    filter {
        includeTestsMatching("*.LoginViewModelTest")
        includeTestsMatching("*.HomeViewModelTest")
        // ... T0+T1 tests
    }
}
```

### Option B: JUnit 5 @Tag annotation (small code changes)

```kotlin
// Add to each smoke test class
@Tag("smoke")
class LoginViewModelTest { ... }

// Run with: ./gradlew test -PincludeTags=smoke
```

Gradle config:
```groovy
tasks.withType<Test> {
    useJUnitPlatform {
        if (project.hasProperty("includeTags")) {
            includeTags(project.property("includeTags") as String)
        }
    }
}
```

### Option C: Test Suite class (explicit grouping)

```kotlin
@RunWith(Suite::class)
@Suite.SuiteClasses(
    LoginViewModelTest::class,
    HomeViewModelTest::class,
    // ... T0+T1 tests
)
class SmokeTestSuite
```

**Recommendation**: Option B (`@Tag`) is cleanest for long-term maintenance — tags are declarative and can be combined with other filters.

## CI Workflow Snippet

```yaml
# Android CI — tiered approach
- name: Run Smoke Tests (T0+T1)
  run: ./gradlew test -PincludeTags=smoke

- name: Run Full Unit Tests (T2, only if smoke passes)
  if: steps.smoke.outcome == 'success'
  run: ./gradlew testDebugUnitTest
```

## Instrumented Test Smoke (UI)

For Espresso UI smoke tests:
```yaml
- name: Run UI Smoke Tests
  run: |
    ./gradlew connectedDebugAndroidTest \
      -Pandroid.testInstrumentationRunnerArguments.annotation=com.example.SmokeTest
```

Requires custom annotation:
```kotlin
@Target(AnnotationTarget.CLASS)
@Retention(AnnotationRetention.RUNTIME)
annotation class SmokeTest
```
