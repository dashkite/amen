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

There's no magic command line interface. You just run your test script with `node` or `coffee` (or the browser). Keep in mind you'll need generator support. For Node, that means running with the `--harmony` flag.

The `describe` method takes an initializer function that allows you to define the tests, runs them for you, and then reports the results.

**Important** Tests are run when they're defined. Consequently, tests nested within other tests may not run if their parent test fails. This prevents running and reporting a bunch of failed tests when there is only one real failure. This is a different way of thinking about testing compared to many other testing frameworks. In Amen, we don't want to report meaningless failures. (Of course, you don't _have_ to nest your tests if don't want to&hellip;)

## Background

The basic intuition for Amen is similar to that of [Testify][]: that test frameworks should basically get out of the way and let you write clear and simple tests. There's no DSL: `assert` is just fine&mdash;and often clearer. There are no mocks because mocking just tells your test suite what it wants to hear. And asynchronous testing should be as simple as possible, but no simpler.

With the standardization of promises and generators in ES6, we had an opportunity to make asynchronous testing even simpler. As you can see in the above example, it's now just a matter of using `yield` (at least in CoffeeScript&mdash;in JavaScript, you also need to use the generator function syntax, but that's still very simple).
