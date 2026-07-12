# How to write a simple test?

When you need to validate straightforward, synchronous logic, the `test` function evaluates a description against your code.

```coffeescript
import { test } from "amen"
import assert from "assert"

# simple synchronous test
await test "A simple test", -> assert true
```

1. Import the `test` function from the `amen` package.
2. Bring in your preferred assertion library.
3. Pass a string description along with your callback function into `test`.
4. Perform your assertion logic within that callback.

# How to write an asynchronous test?

Since many modern applications rely on promises, Amen automatically waits for them to resolve without requiring extra configuration.

```coffeescript
import { test } from "amen"
import assert from "assert"

# complex data fetching
await test "An asynchronous test", ->
  user = await fetchUser()
  assert.equal user.name, "Alice"
```

1. Import the `test` function from the `amen` package.
2. Provide a descriptive string and an asynchronous callback function.
3. Use `await` to handle asynchronous operations natively inside the callback.
4. Run your assertions against the final asynchronous results.

# How to group tests using arrays?

If you have a collection of related tests, you can easily group them together by passing an array of tests instead of a single callback function.

```coffeescript
import { test } from "amen"
import assert from "assert"

# nested test group
await test "A group of tests", [
  test "First test", -> assert true
  test "Second test", -> assert true
]
```

1. Import the `test` function from the `amen` package.
2. Start your `test` call with an overarching description.
3. Instead of a standard callback, pass an array of nested `test` calls.
4. Await the top-level test to resolve the entire suite at once.

# How to use inline configuration?

Sometimes you need specific configurations for individual tests. Amen lets you pass an options object right before the callback to fine-tune behaviors like timeouts or targets.

```coffeescript
import { test } from "amen"
import assert from "assert"

# test with inline timeout and targets
await test "A configured test", { wait: 1000, targets: [ "integration" ] }, ->
  # external long-running integration logic
  result = await runIntegrationProcess()
  assert.ok result
```

1. Import the `test` function from the `amen` package.
2. Provide your descriptive string as usual.
3. Insert an options object containing properties like `wait` (milliseconds) or `targets` (an array of strings).
4. Supply your definition callback as the final argument.

# How to test iterators and asynchronous iterators?

For complex logic encapsulated within iterators, Amen natively consumes Generators and AsyncGenerators by stepping through their yielded values until completion.

```coffeescript
import { test } from "amen"
import assert from "assert"

# asynchronous generator test
await test "An async generator test", ->
  # complex stream consumption
  yield from consumeStream()
  yield assert true
```

1. Import the `test` function from the `amen` package.
2. Define your test logic using a Generator or AsyncGenerator function (utilizing `yield`).
3. Yield the intermediate sequence steps or assertions.
4. Await the `test` call, allowing Amen to fully iterate and evaluate the sequence.

# How to write a pending test?

When you are planning future work but aren't ready to implement the logic, you can define a pending test simply by omitting the callback.

```coffeescript
import { test } from "amen"

# pending test
await test "A future test"
```

1. Import the `test` function from the `amen` package.
2. Call `test` with your descriptive string.
3. Leave out the definition argument completely to automatically flag it as pending.

# How to define a test using an options object?

If you prefer keeping all your parameters in one place, you can encapsulate the entire configuration—including the description—inside a single object.

```coffeescript
import { test } from "amen"
import assert from "assert"

# test defined by options
await test { description: "A fully configured test", wait: 100 }, ->
  assert true
```

1. Import the `test` function from the `amen` package.
2. Pass a single configuration object as the first argument.
3. Embed your `description` string directly within that object.
4. Follow it up with your definition callback as the second argument.

# How to control test ordering and parallelism?

Amen executes grouped tests in parallel by default, but you can enforce sequential execution using the `await` operator directly within your arrays (or by using generator functions).

```coffeescript
import { test } from "amen"
import assert from "assert"

# parallel execution (default for arrays)
await test "Parallel tests", [
  test "First (runs concurrently)", -> await delay 10
  test "Second (runs concurrently)", -> await delay 5
]

# sequential execution using await
await test "Sequential tests", [
  await test "First (runs first)", -> await delay 10
  await test "Second (runs after first)", -> await delay 5
]
```

1. Import the `test` function from the `amen` package.
2. For **parallel** execution, omit the `await` keyword for the nested tests. The array populates with promises, which Amen evaluates concurrently via `Promise.all`.
3. For **sequential** execution, simply prefix your nested `test` calls with `await`. Because JavaScript/CoffeeScript evaluates array literals from left to right, this guarantees that the first test resolves before the second test even begins.
4. (Alternatively, you can also pass a generator function using `yield` for sequential execution, which Amen will natively step through.)
