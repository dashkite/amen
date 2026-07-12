# Amen

*A simple, flexible testing library that supports async functions.*

[![Hippocratic License HL3-CORE](https://img.shields.io/static/v1?label=Hippocratic%20License&message=HL3-CORE&labelColor=5e2751&color=bc8c3d)](https://firstdonoharm.dev/version/3/0/core.html)

Amen is a simple, flexible testing library that supports async functions. It allows you to write clear and simple tests where mock, assert, and report concerns are separate.

## Features

- Amen natively consumes promises out of the box, allowing any asynchronous test logic to be written transparently without relying on complex mock chains.
- You can structure your test suites with arbitrary levels of depth, which keeps closely related components logically grouped.
- When scaffolding new functionality, you can define pending tests without callback bodies to easily flag work for the future.
- Despite weighing in at under fifty lines of code, the core design remains highly extensible by treating everything as a simple function that returns a pair.

## Installation

```bash
pnpm install -D amen
```

## Usage

Amen exports a `test` function and a `print` function. Tests can be asynchronous and nested.

```coffeescript
import {print, test} from "amen"

assert = require "assert"

# a few async functions to test

good = ->
  new Promise (resolve) ->
    setTimeout resolve, 100

bad = ->
  new Promise (_, reject) ->
    setTimeout (-> reject new Error "oops"), 100

never = -> new Promise ->

do ->
  print await test "Using Amen to test itself", [
    test "A simple test", -> assert true
    test "A nested test", [
      test "I'm nested", -> assert true
    ]
    test "A failing test", -> assert false
    test "A nested group of async tests", [
      test "An async test", -> await good()
      test "A failing async test", -> await bad()
      test "An async test that never resolves", -> await never()
    ]
    test "A pending test"
  ]
```

This would generate output like this:

![Screen shot of output.](./docs/screen-shot.png)

## Running Tests

There's no magic command line interface. You run your tests however you like.

Amen exports a `success` value that indicates whether any tests have failed. You can import this if you want to take some action (say, like exiting with a non-zero status code) based on the success or failure of the tests.

## Background

The basic intuition for Amen is that test frameworks should basically get out of the way and let you write clear and simple tests. Mocks, asserts, reporting, and so on should be separate concerns.

Async functions also make it simpler now to handle asynchronous testing. Any test can simply return a promise.

Amen is so far less than fifty lines of code, yet extensible. Any function that returns a pair (an array with two elements, the description and either a test result or an array of pairs) can be used as a test function. Any function that can handle that as input can be a reporting function.

As is, Amen can handle nested tests, async tests, and pending tests.

## Other Resources

- [Reference](docs/reference.md)
- [Recipes](docs/recipes.md)
- [Technical Notes](docs/technical-notes.md)
- [Testing Guide](docs/testing.md)
