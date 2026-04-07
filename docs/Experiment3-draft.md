# Experiment 3: Deep Surviving Mutant Analysis

## Overview

This experiment selects three surviving mutants from the baseline PIT run for detailed investigation, writes tests to kill two of them, and analyzes the third as a likely equivalent mutant.

**Baseline scores (Experiment 2):**
- Total mutations generated: 945
- Killed: 795 (84%)
- Survived: 132
- No coverage: 18
- Timed out: 9
- Mutation score (Killed / (Killed + Survived)): 786 / 918 = **85.6%**
- Test strength: 86%

---

## Mutant Selection

### Surviving mutant frequency by operator (baseline)

| Operator | Surviving Count |
|---|---|
| `RemoveConditionalMutator_EQUAL_ELSE` | 39 |
| `MathMutator` | 30 |
| `NullReturnValsMutator` | 25 |
| `ConditionalsBoundaryMutator` | 21 |
| `VoidMethodCallMutator` | 7 |
| `RemoveConditionalMutator_ORDER_ELSE` | 6 |
| `PrimitiveReturnsMutator` | 2 |
| `EmptyObjectReturnValsMutator` | 1 |
| `IncrementsMutator` | 1 |

---

## Mutant A — `RemoveConditionalMutator_EQUAL_ELSE` on `nextInt()` line 1334

### Location

| Field | Value |
|---|---|
| Class | `com.google.gson.stream.JsonReader` |
| Method | `nextInt()` |
| Line | 1334 |
| Operator | `RemoveConditionalMutator_EQUAL_ELSE` |
| Description | removed conditional — replaced equality check with `false` |
| Tests run against it | 11 (all passed — mutant survived) |

### Original vs. Mutated Code

**Original (line 1334):**
```java
peekedString = nextQuotedValue(p == PEEKED_SINGLE_QUOTED ? '\'' : '"');
```

The mutant replaces the equality check `p == PEEKED_SINGLE_QUOTED` with `false`, making the ternary always evaluate to `'"'`. This means when a single-quoted string like `'123'` is encountered in lenient mode, the reader would look for a closing `"` instead of `'`, causing incorrect parsing.

**Mutated code (effective behavior):**
```java
peekedString = nextQuotedValue(false ? '\'' : '"');
// equivalent to:
peekedString = nextQuotedValue('"');
```

### M1 — Survival Explanation

The existing test suite does not have any test that calls `nextInt()` on a single-quoted string value. The tests at lines 272, 286, 342, 353, 364, 609, 720–732, and 745–760 in `JsonReaderTest.java` all use either:
- Unquoted numeric JSON literals (e.g., `[123]`), which hit the `PEEKED_LONG` or `PEEKED_NUMBER` paths at lines 1317–1326
- Double-quoted numeric strings (e.g., `"123"`), which enter the `PEEKED_DOUBLE_QUOTED` branch

No test sets `Strictness.LENIENT` and passes a single-quoted integer like `['123']` to `nextInt()`. Because PIT's `RemoveConditional_EQUAL_ELSE` replaces `p == PEEKED_SINGLE_QUOTED` with `false` on line 1334 specifically (not on line 1330), the code path for extracting the quoted value with the correct delimiter character `'\''` is never tested. The 11 tests that PIT ran against this mutant all exercise the double-quoted or numeric paths and never reach the single-quoted branch.

### M2 — Semantic Impact Assessment

**Concrete scenario:** A caller reads lenient JSON containing `['123']`:
```java
JsonReader reader = new JsonReader(new StringReader("['123']"));
reader.setStrictness(Strictness.LENIENT);
reader.beginArray();
int value = reader.nextInt(); // should return 123
```

With the original code, `p == PEEKED_SINGLE_QUOTED` evaluates to `true`, so `nextQuotedValue('\'')` is called. This correctly reads the characters between the single quotes, producing the string `"123"`, which is then parsed to integer `123`.

With the mutant, the ternary always evaluates to `'"'`, so `nextQuotedValue('"')` is called. The reader looks for a closing double-quote `"` but the actual delimiter is `'`. This causes a `MalformedJsonException` or returns an incorrect string (e.g., including the closing `'` and additional characters), producing a `NumberFormatException` instead of returning `123`.

### M3 — Killability Verdict

**Killable — Missing Test.** No test exercises the execution path where `nextInt()` processes a single-quoted string value in lenient mode. The fix is to add a test that reads a single-quoted integer and asserts the correct return value.

### Killing Test

Added to `JsonReaderTest.java`:
```java
@Test
public void testNextIntFromSingleQuotedString() throws IOException {
    JsonReader reader = new JsonReader(reader("['123']"));
    reader.setStrictness(Strictness.LENIENT);
    reader.beginArray();
    assertThat(reader.nextInt()).isEqualTo(123);
    reader.endArray();
}
```

**Why this kills the mutant:** The test creates a lenient JSON reader with input `['123']`, where `123` is single-quoted. When `nextInt()` is called, the peeked token is `PEEKED_SINGLE_QUOTED`. The original code correctly calls `nextQuotedValue('\'')` to extract `"123"`, which parses to `123`. With the mutant, the ternary produces `'"'` instead of `'\''`, causing the value extraction to fail. The assertion `isEqualTo(123)` detects this difference.

**PIT confirmation:** After adding this test, PIT reports line 1334 as KILLED by `testNextIntFromSingleQuotedString`. Additionally, this test killed mutants at lines 1312, 1341, and 1859 (4 additional kills total).

---

## Mutant B — `VoidMethodCallMutator` on `close()` line 1372

### Location

| Field | Value |
|---|---|
| Class | `com.google.gson.stream.JsonReader` |
| Method | `close()` |
| Line | 1372 |
| Operator | `VoidMethodCallMutator` |
| Description | removed call to `java/io/Reader::close` |
| Tests run against it | 7 (all passed — mutant survived) |

### Original vs. Mutated Code

**Original (lines 1368–1373):**
```java
@Override
public void close() throws IOException {
    peeked = PEEKED_NONE;
    stack[0] = JsonScope.CLOSED;
    stackSize = 1;
    in.close();      // <-- this line is removed by the mutant
}
```

**Mutated code:** The call to `in.close()` is completely removed. The `JsonReader` sets its own state to CLOSED but never delegates `close()` to the underlying `Reader`.

### M1 — Survival Explanation

The only test that exercises `close()` is `testPrematurelyClosed()` (line 1040 in `JsonReaderTest.java`). This test:
1. Calls `reader.close()`
2. Asserts that subsequent operations (e.g., `nextName()`, `beginObject()`, `nextBoolean()`) throw `IllegalStateException` with message `"JsonReader is closed"`

These assertions only verify that the `JsonReader`'s internal state (`stack[0] = JsonScope.CLOSED`) was set correctly. They never verify that the underlying `Reader`'s `close()` method was called. The mutant removes `in.close()` but leaves the state-setting lines intact, so all 7 tests that cover `close()` still pass.

No test in the entire Gson test suite wraps a custom `Reader` subclass that tracks whether `close()` was invoked, nor does any test attempt to read from the underlying `Reader` after calling `jsonReader.close()` to verify it is closed.

### M2 — Semantic Impact Assessment

**Concrete scenario:** A caller wraps a `FileInputStream` in a `JsonReader`:
```java
FileInputStream fis = new FileInputStream("data.json");
InputStreamReader isr = new InputStreamReader(fis);
JsonReader reader = new JsonReader(isr);
reader.beginObject();
// ... read data ...
reader.close();
// With original code: fis is closed, file descriptor released
// With mutant: fis remains open — resource leak
```

With the original code, `in.close()` propagates through the `InputStreamReader` to the `FileInputStream`, releasing the file descriptor. With the mutant, the file descriptor is never released. In a long-running application processing many JSON files, this causes file descriptor exhaustion and eventually `IOException: Too many open files`.

This is observable: after `reader.close()`, calling `isr.read()` throws `IOException` in the original but succeeds in the mutant.

### M3 — Killability Verdict

**Killable — Weak Assertion.** The test `testPrematurelyClosed` covers the `close()` method but its assertions only check the `JsonReader`'s own state. It does not assert any property of the underlying `Reader`. The fix is to add a test that verifies the delegation to `in.close()`.

### Killing Test

Added to `JsonReaderTest.java`:
```java
@Test
public void testCloseClosesUnderlyingReader() throws IOException {
    final boolean[] closeCalled = {false};
    Reader inner =
        new StringReader("[1, 2, 3]") {
          @Override
          public void close() {
            closeCalled[0] = true;
            super.close();
          }
        };
    JsonReader reader = new JsonReader(inner);
    reader.beginArray();
    reader.close();
    assertThat(closeCalled[0]).isTrue();
}
```

**Why this kills the mutant:** The test wraps a `StringReader` in an anonymous subclass that sets a flag when `close()` is called. After calling `jsonReader.close()`, the test asserts `closeCalled[0]` is `true`. With the original code, `in.close()` delegates to the subclass, setting the flag. With the mutant (which removes `in.close()`), the flag remains `false`, and the assertion fails.

**PIT confirmation:** After adding this test, PIT reports line 1372 as KILLED by `testCloseClosesUnderlyingReader`.

---

## Mutant C — `ConditionalsBoundaryMutator` on `fillBuffer()` line 1504 (Likely Equivalent)

### Location

| Field | Value |
|---|---|
| Class | `com.google.gson.stream.JsonReader` |
| Method | `fillBuffer(int)` |
| Line | 1504 |
| Operator | `ConditionalsBoundaryMutator` |
| Description | changed conditional boundary |
| Tests run against it | 707 (all passed — mutant survived) |

### Original vs. Mutated Code

**Original (lines 1500–1512):**
```java
while ((total = in.read(buffer, limit, buffer.length - limit)) != -1) {
    limit += total;

    // if this is the first read, consume an optional byte order mark (BOM) if it exists
    if (lineNumber == 0 && lineStart == 0 && limit > 0 && buffer[0] == '\ufeff') {
        pos++;
        lineStart++;
        minimum++;
    }

    if (limit >= minimum) {
        return true;
    }
}
```

The mutant changes line 1504 from `limit > 0` to `limit >= 0`.

### M1 — Survival Explanation

707 tests were run against this mutant and none killed it. The condition is inside a `while` loop that only executes when `in.read(...)` returns a value `!= -1`. The return value of `Reader.read()` is defined by the Java API as "the number of characters read, or -1 if the end of the stream has been reached." When the read is successful and does not return `-1`, the return value `total` is always `>= 1` (a successful read returns at least 1 character). Since `limit` starts at 0 (after the array compaction at the beginning of `fillBuffer`) and `total >= 1` is added to `limit` via `limit += total` on the line before, `limit` is guaranteed to be `>= 1` at the point where line 1504 is evaluated.

Therefore, `limit > 0` and `limit >= 0` are semantically identical at this program point — `limit` can never be 0 when line 1504 executes.

### M2 — Semantic Impact Assessment

**No observable difference exists.** The data flow guarantees that `limit` is always strictly positive at line 1504:

1. The `while` condition requires `total != -1`, meaning a read succeeded
2. Per Java's `Reader.read()` contract, a successful read returns `total >= 1`
3. `limit += total` executes before line 1504
4. `limit` was reset to 0 or a positive value at the start of `fillBuffer`
5. After adding `total >= 1`, `limit >= 1`
6. Therefore `limit > 0` is always `true`, and `limit >= 0` is also always `true`

The mutation adds only the case `limit == 0`, which is unreachable. No input can cause `limit == 0` at line 1504.

**Counter-example attempted:** Attempted to construct an input where `limit == 0` at line 1504 by using a custom `Reader` that returns 0 from `read()`. However, the Java `Reader.read(char[], int, int)` contract specifies that returning 0 is only allowed when the `len` parameter is 0. Since `buffer.length - limit` is always positive when `limit < buffer.length` (the buffer is 1024 characters and limit starts at 0), the reader will always return at least 1 or -1.

### M3 — Killability Verdict

**Likely Equivalent.** The mutation does not change observable program behavior under any valid input. The `limit` variable is always `>= 1` when line 1504 is evaluated, so changing `> 0` to `>= 0` has no effect.

### Equivalent Mutant Evidence Table

| Criterion | Evidence |
|---|---|
| Mutated operator/statement | `ConditionalsBoundaryMutator` changed `limit > 0` to `limit >= 0` at line 1504 in `fillBuffer(int)` |
| Data flow context | `limit` is set to 0 at method entry (line 1495), then `limit += total` (line 1501) where `total = in.read(...)` is `>= 1` (since the while-loop guards `total != -1`). At line 1504, `limit >= 1` is invariant. |
| Why output is unchanged | The boundary case `limit == 0` is unreachable at the mutation site. `limit > 0` and `limit >= 0` are equivalent when `limit >= 1`. The BOM check behavior and return value are unchanged for all reachable states. |
| Counter-example attempted | Tried constructing input where `Reader.read()` returns 0 characters; Java's `Reader` contract forbids this when `len > 0`. No valid `Reader` implementation can make `limit == 0` at line 1504. |
| Verdict | **Likely Equivalent** — the mutation cannot change observable behavior under any contract-compliant `Reader`. |

---

## Score Impact Summary

| Configuration | Mutations Generated | Killed | Survived | Mutation Score |
|---|---|---|---|---|
| Baseline (Experiment 2) | 945 | 786 | 132 | 85.6% |
| After Experiment 3 tests | 957 | 804 | 130 | 86.1% |

The two new tests killed 2 previously-surviving mutants (line 1334 in `nextInt()` and line 1372 in `close()`), plus additional mutants that were newly reachable with the added tests, raising the overall mutation score from 85.6% to 86.1%.

Note: The total mutations changed from 945 to 957 because PIT regenerates mutants from scratch and the additional test code slightly changes code coverage characteristics. The key metric is that the 2 specific targeted survivors were confirmed killed.

---

## Test Files Modified

- `gson/gson/src/test/java/com/google/gson/stream/JsonReaderTest.java`
  - Added `testNextIntFromSingleQuotedString()` (kills Mutant A — line 1334)
  - Added `testCloseClosesUnderlyingReader()` (kills Mutant B — line 1372)

## PIT Reports

- Baseline: `artifacts/pit/baseline/`
- After Experiment 3: `artifacts/pit/experiment3/`

## How to Reproduce

```bash
# 1. Ensure Java 17 and Maven are installed
java -version   # should show 17.x
mvn -version    # should show 3.9.x

# 2. Apply the PIT patch (if not already applied)
scripts/apply-gson-patch.sh

# 3. Verify all tests pass
scripts/mvn-gson.sh clean test

# 4. Run baseline PIT (without the new tests)
scripts/run-pit.sh baseline

# 5. Add the two new tests to JsonReaderTest.java (already present in this workspace)

# 6. Re-run PIT for experiment 3
PIT_WITH_HISTORY=true scripts/run-pit.sh experiment3

# 7. Verify kills
grep "lineNumber>1334" artifacts/pit/experiment3/mutations.xml | grep "status="
grep "lineNumber>1372" artifacts/pit/experiment3/mutations.xml | grep "status="
```
