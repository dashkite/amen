colors = require "colors"
{promise, lift} = require "when"
generator = require "when/generator"
async = generator.lift
{call} = generator

class Context

  @describe: (description, fn) ->
    (new Context description)._run fn

  constructor: (@description, @parent) ->
    @parent?.kids.push @
    @kids = []
    @root = @parent?.root || @

  _run: (fn) ->
    self = @
    call ->
      self.pending = 0
      yield promise (resolve) ->
        self.resolve = resolve
        fn self
        resolve() if self.pending == 0
      self.report()

  start: -> ++@pending
  finish: ->
    --@pending
    @resolve() if @pending == 0

  # Main entry point for using Amen
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
        self = @
        self.root.start()
        call ->
          try
            yield (call fn, self)
            self.pass()
          catch error
            self.fail error
          self.root.finish()
      else
        try
          fn @
          @pass()
        catch error
          @fail error
    else
      @fail()

  pass: ->
    @result ?= true

  fail: (error) ->
    console.error error.stack if error?.stack?
    @result = false
    @error = error

  report: (indent="") ->
    console.log indent,

      if @result?
        if @error?
          "#{@description} [#{@error}]".red
        else if @result
          @description.green
        else
          @description.yellow
      else
        @description.bold.green

    (kid.report (indent + "  ")) for kid in @kids

module.exports = Context
