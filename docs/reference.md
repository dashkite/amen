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
- **options**: An object containing options (e.g. `{ targets: [...] }` or `{ wait: 1000 }`).
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

A conditional helper that executes test arguments only if matching tags or substrings are provided in the environment variable.

$target: \text{targets}, \text{args} \dashrightarrow \text{test}$

- **targets**: A string tag or array of tag strings.
- **args**: The arguments normally passed to the `test` factory.

#### Example

```coffeescript
import { target } from "@dashkite/amen"

# Only runs if target environment variable matches "deploy"
target "deploy", "Deploy DB Schema", ->
  # ...
```

## Classes

All test instances returned by the `test` factory inherit from the base `AbstractTest` class.

### AbstractTest

The base class defining properties, thenable/catchable interfaces, and the async iterator.

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

$run: \dashrightarrow \text{promise}$
$then: \text{on\_fulfilled}, \text{on\_rejected} \dashrightarrow \text{promise}$
$catch: \text{on\_rejected} \dashrightarrow \text{promise}$

- **run**: Executes the test definition. Automatically wrapped in a `once` combinator so execution is cached and safe.
- **then / catch**: Promise integration allowing instances to be awaited.

### TestGroup

Subclass of `AbstractTest` representing a suite that aggregates child tests. It runs its children in parallel and concurrent-merges their execution event streams.

### RunnableTest

Subclass of `AbstractTest` representing a leaf test case with a definition function. Executes synchronous functions, Promises, Generators, and Async Generators with optional timeout handling.

### PendingTest

Subclass of `AbstractTest` representing a placeholder/pending test that has no definition.

### ComputedTest

Subclass of `AbstractTest` wrapping raw values, Promises, or arrays without descriptions.
