# Amen

Amen is a simple testing library that uses promises and generators to simplify testing asynchronous functions.

## Modules

Amen uses colors to display the output.

    colors = require "colors"

We use the [when][] promise library to run asynchronous tests and keep track of when they've completed.

    {promise} = require "when"
    {call, lift} = require "when/generator"

[when]:https://github.com/cujojs/when

## Context

An Amen test suite basically consists of a tree of Contexts. The `root` Context is the root of the tree. Each context is created with a description and a function which can define further (nested) Contexts.

**Important** Tests are run as they're defined. Consequently, tests nested within other tests may not run if their parent test fails. This prevents running and reporting a bunch of failed tests when there is only one failure. This is a different way of thinking about testing compared to many other testing frameworks. In Amen, we don't want to report meaningless failures.

    class Context

### Pending Tests

The `pending` property keeps track of how many tests are still running. We can use a simple counter because we don't yield the event loop until all the tests have been started.

      @pending = 0

### Describing a Test Suite

The class `describe` method kicks things off. We create a `root` context, run the initializer function (given as `fn`) and wait for all the pending tests to return. Once we're done, we run `report` on the `root`.

      @describe: (description, fn) ->

We use `call` here because we're going to `yield` until we get all the results back.

        call =>
          @root = new Context description

#### Waiting for Asynchronous Tests to Complete

We create a promise here and then yield to it. We use CoffeeScript's convenient property initializer to attach the resolve function to the `Context` object itself. (This means we can't run multiple test suites.) Within the resolver function, we call the initalizer function, passing in the `root` context.

          fn @root
          if @pending > 0
            yield (promise (@resolve) =>)
          @report()

### Reporting

The `Context.report` function just call the `report` method for the root context.

      @report: -> @root.report()

### The `async` Helper Function

When we're given an asynchronous test, we need to keep track of it, incrementing and decrementing the `pending` counter, and calling `resolve` if the counter reaches zero. Since we `yield` when we call the function, we wrap all this in `call`. We'll call this function from the `test` method for a context.

      @async: (fn, context) ->
        fn = lift fn
        call =>
          @pending++
          yield fn context
          @resolve() if --@pending == 0

### Constructing a Context

Constructing a context is pretty straightforward. We add ourselves to the parent, if one is passed to us, and initialize our own kids array.

      constructor: (@description, @parent) ->
        @parent?.kids.push @
        @kids = []

### Describing a Nested Context

Sometimes you want a context that doesn't actually contain a test, just a category of tests. That's what the `describe` method is for. We create a new context, passing in the description, and then pass that to the given initializer function.

      describe: (description, fn) ->
        fn(new Context(description, @))

### Running a Test

Now the fun begins: running a test requires a description of the test and an optional function to run it. It's optional because the lack of a function is how we indicate a pending test. The function can be a generator function, which means it's an asynchronous test, in which case we use the `Context.async` helper to run it. Otherwise, it's just a normal test.

      test: (description, fn) ->

First, we create the context for the test.

        context = new Context description, @

If we have a test function, we're going to try and run it.

        if fn?

We'll wrap everything in a `try/catch` block, which works because we're using promises to wrap asynchronous tests.

          try

#### Detecting Asynchronous Tests

We can tell if we get a generator function because the constructor name will tell us. We'll call it with `Context.async`, described above.

            if fn.constructor.name == "GeneratorFunction"
              Context.async fn, context

Otherwise, it's just an ordinary synchronous function and we just call it, passing in the context in case the test wants to define any nested tests.

            else
              fn(context)

If we've gotten here, the test ran and didn't throw, so we record it as passing.

            context.pass()

Otherwise, we've thrown for some reason. We dump the stack trace immediately and then record the failure.

          catch error
            console.error error.stack
            context.fail error

#### Handling Pending Tests

If a test function wasn't provided, we record that as a failure, with no error.

        else
          context.fail()

### Passing and Failing Tests

Passing tests are easy: we just record that we got a result. (Contexts with no results are either pending tests or contexts that only contain other tests.)

      pass: ->
        @result = true

Failing tests also need to record the error.

      fail: (error) ->
        @result = false
        @error = error

### Reporting Results

Result reporting is pretty simple. If there's a result, we report it, otherwise we simply display a description in bold. An error result is red, a failing result with no error (that is, a pending test) is yellow, and a passing test is, of course, green. We indent the results of nested contexts.

We start with an empty indent:

      report: (indent="") ->

Display the indent and then evaluate the conditional expression.

        console.log indent, if @result?

If we got an error, we display that in red.

          if @error?
            "#{@description} [#{@error}]".red

Otherwise, depending on the result (`true` or `false`), we display the description in green or yellow&hellip;

          else
            color = (if @result then "green" else "yellow")

&hellip;and return the description, encoded with the appropriate color.

            @description[color]

If there was no result, we assume this context just holds other contexts, so we display the description in bold, to make it stand out like a heading.

        else if @description?
          @description.bold.green

We've displayed our result, so we can move onto our children if we haven any.

        (kid.report (indent += "  ")) for kid in @kids

### Exports

We export the `Context` class and clients can call `describe` to describe (and run) their test suite.

    module.exports = Context
