# test

The `test` function pairs a human-readable description with a functional definition to evaluate a scenario.

```coffeescript
import { test } from "amen"
import assert from "assert"

assert.ok await test "A test", -> true
```

$test: description, definition \dashrightarrow result\_pair$

$test: options, definition \dashrightarrow result\_pair$

$test: description, options, definition \dashrightarrow result\_pair$

# print

The `print` function takes a resulting test pair and streams the output to standard error for visibility.

```coffeescript
import { test, print } from "amen"

print await test "A test", -> true
```

$print: result\_pair \to \emptyset$

# success

The `success` property tracks the overall health of the test suite throughout the process lifecycle. It starts out as `true`, but immediately flips to `false` the moment any individual test fails.

```coffeescript
import { success } from "amen"
import assert from "assert"

assert.equal success, true
```

$success \to boolean$
