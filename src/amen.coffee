colors = require "colors"
{promise, lift} = require "when"
generator = require "when/generator"
async = generator.lift
{call} = generator

class Context

  # Some internal bookkeeping to keep track of outstanding tests
  pending = 0
  resolve = null
  wait = ->
    promise (_resolve) ->
      resolve = _resolve
      resolve() unless pending > 0

  start = -> ++pending
  finish = -> resolve() if --pending == 0

  # Main entry point for using Amen
  @describe: (description, fn) ->
    call =>
      @root = new Context description
      fn @root
      yield wait()
      @root.report()

  constructor: (@description, @parent) ->
    @parent?.kids.push @
    @kids = []

  describe: (description, fn) ->
    fn(new Context(description, @))

  test: (description, fn) ->
    (new Context description, @).run fn

  # This looks like it should be refactored, but it's a bit tricky because
  # the call to finish must happen, regardless of whether the test passes.
  # And we can't call start/finish for non-async tests because we use
  # a simple counter instead of queuing up all the async tests in a group.
  # Basically, the simplicity of the counter pushes the complexity here.
  run: (fn) ->
    if fn?
      if fn.constructor.name == "GeneratorFunction"
        call =>
          start()
          try
            yield (call fn, @)
            @pass() unless @result?
          catch error
            @fail error
          finish()
      else
        try
          fn @
          @pass() unless @result?
        catch error
          @fail error
    else
      context.fail()

  pass: ->
    @result = true

  fail: (error) ->
    console.error error.stack if error?.stack?
    @result = false
    @error = error

  report: (indent="") ->
    console.log indent,

      if @result?
        if @error?
          @description.red
        else if @result
          @description.green
        else
          @description.yellow
      else
        @description.bold.green

    (kid.report (indent + "  ")) for kid in @kids

module.exports = Context
