# Reference Guide

This reference details the API signatures and class structures of `@dashkite/amen`.

## Functions

### test

The main factory function used to define tests. It is implemented as a Generic dispatcher and routes arguments based on their signatures.

$test: \text{description} \dashrightarrow \text{pending\_test}$
$test: \text{options} \dashrightarrow \text{pending\_test}$
$test: \text{description}, \text{definition} \dashrightarrow \text{test}$
$test: \text{options}, \text{definition} \dashrightarrow \text{test}$
$test: \text{description}, \text{options}, \text{definition} \dashrightarrow \text{test}$

- **description**: A string describing the test or group.
- **options**: An object containing configuration properties. When no separate description string is passed, the options object must include the `description` property to name the test. Supported properties:
  - `description`: The test name or description.
  - `targets`: A tag string or array of tags for conditional test targeting.
  - `active`: A tag string or array of tags representing the active target filters. Only tests matching these targets will run.
  - `wait`: A timeout duration limit in milliseconds for asynchronous executions.
- **definition**: One of:
  - A function (synchronous, promise-returning, generator, or async generator) for a standard test case.
  - An iterable of child tests for a group definition.
  - A raw value or Promise.
- **test**: An instance of a subclass of `AbstractTest`.

#### Example

```coffeescript
import { test } from "@dashkite/amen"

# A pending test
pending = test "Implement this later"

# A leaf test
leaf = test "Add numbers", ->
  assert.equal ( 1 + 2 ), 3

# A group of tests with options
suite = test "API Suite", { targets: [ "api" ] }, [
  test "Endpoint A", -> # ...
]
```

### print

A reporter that consumes test results and prints them to the console. It supports both live iteration of async iterators (for real-time reporting) and legacy resolved result trees.

$print: \text{target} \dashrightarrow \emptyset$

- **target**: Either an instance of `AbstractTest` (consumed via its async iterator) or a legacy resolved result tree array.

#### Example

```coffeescript
import { test, print } from "@dashkite/amen"

# Live printing as the tests run
await print test "My Suite", [
  test "test a", -> # ...
]
```

### target

A conditional helper that injects targeting tags into the test options. The test will only execute if its targets match the active targets of its parent group.

$target: \text{targets}, \text{args} \dashrightarrow \text{test}$

- **targets**: A string tag or array of tag strings.
- **args**: The arguments normally passed to the `test` factory.

#### Example

```coffeescript
import { target } from "@dashkite/amen"

# Only runs if the parent group's active target contains "deploy"
target "deploy", "Deploy DB Schema", ->
  # ...
```

## Classes

All test instances returned by the `test` factory inherit from the base `AbstractTest` class.

### AbstractTest

The base class defining properties, setup/teardown hooks, and the async iterator.

#### Properties

$status \to \text{string}$
$description \to \text{string}$
$parent \to \text{test}$
$children \to \text{array}$

- **status**: The current test state: `"pending"`, `"running"`, `"passed"`, `"failed"`, or `"skipped"`.
- **description**: The name of the test (if provided).
- **parent**: Reference to the parent `TestGroup` (if nested).
- **children**: An array of child test instances (for groups).

#### Methods

$before: \text{callback} \to \text{test}$
$after: \text{callback} \to \text{test}$
$run: \dashrightarrow \text{promise}$

- **before**: Registers a synchronous or asynchronous callback to run before the test execution begins. The context `this` (`@`) within the callback is bound to the test instance. Returns the test instance for method chaining.
- **after**: Registers a synchronous or asynchronous callback to run in a `finally` block after the test execution completes, regardless of success or failure. The context `this` (`@`) within the callback is bound to the test instance. Teardown failures in `after` hooks fail the test. Returns the test instance for method chaining.
- **run**: Executes the test definition. Automatically wrapped in a `once` combinator so execution is cached and safe.

### TestGroup

Subclass of `AbstractTest` representing a suite that aggregates child tests. It runs its children in parallel and concurrent-merges their execution event streams.

### RunnableTest

Subclass of `AbstractTest` representing a leaf test case with a definition function. Executes synchronous functions, Promises, Generators, and Async Generators with optional timeout handling.

### PendingTest

Subclass of `AbstractTest` representing a placeholder/pending test that has no definition.

### ComputedTest

Subclass of `AbstractTest` wrapping raw values, Promises, or arrays without descriptions.
