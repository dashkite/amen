# Recipes Guide

This guide provides task-based recipes for common testing scenarios in `@dashkite/amen`.

## Requisite Imports

All recipes assume the following baseline imports:

```coffeescript
import assert from "assert"
import { test, print, target } from "@dashkite/amen"
```

## Recipes

### 1. Writing Async Tests with Timeouts

#### Task
Set a maximum execution time limit for long-running asynchronous test cases.

#### How the software enables the task
Pass the `wait` option (in milliseconds) to the test options. If the test definition does not resolve within the specified limit, Amen rejects it and marks the test as failed.

#### Code Example
```coffeescript
# Test fails if query takes longer than 500ms
test "Fetch records within time limit", { wait: 500 }, ->
  # fetchRecords() returns a Promise
  await fetchRecords()
```

#### Algorithm
1. Pass an options object containing `wait: limit_in_ms` to the test factory.
2. Provide a Promise-returning or async function definition.
3. The runner wraps the execution in a timeout race, automatically clearing the timer on success or rejecting with a timeout exception on expiry.

### 2. Real-Time Live Logging

#### Task
Stream test results to the terminal as they execute rather than waiting for the entire suite to finish.

#### How the software enables the task
Pass the test suite instance directly to the `print` function. Because the test suite implements `[Symbol.asyncIterator]`, the `print` function consumes and prints the execution events (`test:start`, `test:success`, etc.) on the fly.

#### Code Example
```coffeescript
do ->
  await print test "My Heavy Suite", [
    test "Fast check", -> assert true
    test "Slow network check", ->
      # simulated network delay
      new Promise ( resolve ) -> setTimeout resolve, 2000
    test "Final check", -> assert true
  ]
```

#### Algorithm
1. Create a suite using `test` with a children array.
2. Pass the unawaited suite instance directly to `print`.
3. Await the `print` promise. The console reporter consumes and live-renders the async iteration events in real-time.

### 3. Filtering Test Execution by Environment Variables

#### Task
Run a specific subset of tests locally or in CI without modifying test code files.

#### How the software enables the task
Attach tags to test options or filter by description substring. Then run your test suite with the `targets` environment variable.

#### Code Example
```coffeescript
test "Full Suite", [
  test "Quick Check", -> assert true
  test "Slow Integration Check", { targets: [ "slow", "integration" ] }, ->
    # slow operations here
    assert true
]
```

To run only the slow checks, execute the test script from the terminal:

```bash
targets="slow" node build/node/test/index.js
```

#### Algorithm
1. Add a `targets` option (string or array of strings) to targeted tests or groups.
2. Set the `targets` (or `TARGETS`, `target`, `TARGET`) environment variable when running the script.
3. Amen dynamically checks matches on description names and tags, propagating skipped states down to nested child tests when targets don't match.
