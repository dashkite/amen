# Amen

Amen is a very simple testing framework utilizing promises and generators for asynchronous testing.

```coffeescript
amen.describe "My simple test suite", (context) ->

  context.describe "My synchronous tests", (context) ->

  context.test "A simple test", -> assert true

  context.test "A nested test", (context) ->

    context.test "I'm nested!", -> assert true

  context.test "A failing test", -> assert false

  context.describe "My asynchronous tests", (context) ->

    # Two very contrived async functions

    good = -> promise (resolve) -> setTimeout resolve, 100

    bad = ->
      promise (resolve, reject) ->
        setTimeout (-> reject (new Error "oops")), 100

    context.test "An asynchronous test", -> yield good()

    context.test "A failing asynchronous test", -> yield bad()
```

## Installation

```
npm install amen
```

## Running Tests

There's no magic command line interface. You just run your test script with `node` or `coffee` (or the browser).

The `describe` method takes an initializer function that allows you to define the tests, runs them for you, and then reports the results.

## Background

The basic intuition for Amen is similar to that of [Testify][]: that test frameworks should basically get out of the way and let you write clear and simple tests. There's no DSL: `assert` is just fine&mdash;and often clearer. There is no built-in mechanism for mocks since that's a separate concern and different mock libraries are appropriate for different scenarios.

[Testify]:https://github.com/pandastrike/testify

With the standardization of promises and generators in ES6, we had an opportunity to make asynchronous testing even simpler. As you can see in the above example, it's now just a matter of defining a generator function instead of an ordinary function. Amen detects that and runs it as a generator for you automatically.
