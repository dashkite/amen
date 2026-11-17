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

### 3. Filtering Test Execution (Targeting)

#### Task
Run a specific subset of tests dynamically across modes and scenarios using hierarchical `targets` options.

#### How the software enables the task
Attach `targets` options to test groups and/or leaf tests. Set the `active` targets on the root suite using the `active` option or the `active` instance property. When multiple nodes in a test's ancestor-to-self lineage define `targets` (for example, a scenario target on a parent group and a mode target like `"compile"` or `"validate"` on child tests), every targeted node in the lineage must match `active` for the test to execute.

The test runner determines which targets are active and can apply sensible defaults (such as defaulting to fast validation tests across all scenarios when `process.env.targets` is unset).

#### Code Example
```coffeescript
import { test, print } from "@dashkite/amen"

scenarios = [ "blog-platform", "ecommerce-storefront" ]
modes = [ "compile", "validate" ]

# Compute active targets with runner defaults
specified = process.env.targets?.split( /\s+/ ).filter( Boolean ) ? []
active = [ specified... ]

unless active.some ( item ) -> item in modes
  active.push "validate"

unless active.some ( item ) -> item in scenarios
  active.push scenarios...

suite = test "Full Suite", { active }, (
  for name in scenarios
    test name, { targets: name }, [
      test "compilation", { targets: "compile" }, ->
        # Slow compilation test (skipped by default)
        assert true
      test "validation", { targets: "validate" }, ->
        # Fast validation test (runs by default)
        assert true
    ]
)

await print suite
```

Run only the fast validation checks (default):

```bash
pnpm test
```

Run only the compilation tests across all scenarios:

```bash
targets=compile pnpm test
```

Run validation for a single scenario:

```bash
targets=blog-platform pnpm test
```

#### Algorithm
1. Add a `targets` option (string or array of strings) to targeted groups and/or leaf tests.
2. Compute the `active` targets array in the test runner (applying defaults for unspecified modes or scenarios) and pass `{ active }` to the root suite.
3. Amen evaluates each leaf test's lineage: if any node(s) in the lineage define `targets`, all such nodes must match `active`; otherwise the test is marked `"skipped"`.

### 4. Using Setup and Teardown Hooks

#### Task
Perform setup and teardown actions before and after executing a test suite or specific test cases.

#### How the software enables the task
Use the `.before(callback)` and `.after(callback)` methods on any test instance. These methods register setup and teardown callbacks (synchronous or asynchronous) and return the test instance for fluent chaining. Teardown hooks run inside a `finally` block, ensuring they execute even if the test body or setup hooks throw an error.

#### Code Example
```coffeescript
import assert from "assert"
import { test, print } from "@dashkite/amen"

# Mock database resource
database =
  connect: -> new Promise ( resolve ) -> setTimeout resolve, 10
  disconnect: -> new Promise ( resolve ) -> setTimeout resolve, 10
  query: -> [ { id: 1, val: "foo" } ]

suite = test "Database Query Tests", [
  test "reads records", ->
    records = database.query()
    assert.equal records.length, 1
]

# Chain setup and teardown hooks
suite
  .before -> await database.connect()
  .after -> await database.disconnect()

await print suite
```

#### Algorithm
1. Define a test or test group using the `test` factory.
2. Chain `.before(callback)` to register an initialization function. The context `this` (`@`) inside the callback will point to the test instance.
3. Chain `.after(callback)` to register a cleanup function.
4. The runner invokes the setup hook, executes the test body, and invokes the teardown hook inside a `finally` block.

### 5. Sequential Chaining and Dynamic Skipping

#### Task
Execute dependent tests sequentially so downstream tests only run when prerequisite tests succeed, and dynamically skip tests when runtime prerequisites (such as fixtures) are unavailable.

#### How the software enables the task
Call `.and(nextTest)` on any `RunnableTest` or `TestGroup` to create a `TestChain`. Unlike `TestGroup` (which runs children concurrently), `TestChain` runs its children sequentially and automatically skips remaining children if an earlier step fails or is skipped. Inside any test definition, returning `Symbol.for("skipped")` dynamically marks that test as `"skipped"` (and skips any downstream tests chained to it via `.and()`).

#### Code Example
```coffeescript
import assert from "assert"
import { test, print } from "@dashkite/amen"

fixtures = loadFixtures()

suite = test "Specification Validation", [
  ( test "knowledge validation", ->
    unless fixtures?
      return Symbol.for "skipped"
    assert fixtures.knowledge?
  )
    .and test [
      test "security validation", ->
        assert fixtures.security?
      test "caching validation", ->
        assert fixtures.caching?
    ]
]

await print suite
```

#### Algorithm
1. Define the prerequisite test using `test`.
2. Chain dependent tests or groups using `.and(...)`.
3. Return `Symbol.for("skipped")` inside a test definition when runtime preconditions (such as optional fixtures) are missing.
4. If the prerequisite test fails or returns `Symbol.for("skipped")`, the `TestChain` marks all subsequent chained tests as `"skipped"`.
