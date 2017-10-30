# Amen

Amen is a simple, flexible testing library that supports async functions.

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

## Installation

```
npm i -D amen
```

## Running Tests

There's no magic command line interface. You run your tests however you like.


## Background

The basic intuition for Amen is that test frameworks should basically get out of the way and let you write clear and simple tests. Mocks, asserts, reporting, and so on should be separate concerns.

Async functions also make it simpler now to handle asynchronous testing. Any test can simply return a promise.

Amen is so far less than fifty lines of code, yet extensible. Any function that returns a pair (an array with two elements, the description and either a test result or an array of pairs) can be used as a test function. Any function that can handle that as input can be a reporting function.

As is, Amen can handle nested tests, async tests, and pending tests.
