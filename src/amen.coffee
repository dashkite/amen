colors = require "colors"
{inspect} = require "util"
{promise, async} = require "./async-helpers"

class Context

  @pending: 0

  @root = null

  @ready = false

  @start: -> @pending++

  @finish: ->
    @pending--
    @resolve() if @ready && @pending == 0

  @describe: (description, fn) ->
    promise (resolve) ->
      Context.resolve = resolve
      fn(new Context(description))
      Context.ready = true

  constructor: (@description, @parent) ->
    Context.root ?= @
    @parent?.kids.push @
    @kids = []

  describe: (description, fn) ->
    context = new Context description, @
    fn context

  test: (description, fn) ->
    context = new Context description, @
    Context.pending++
    if fn.constructor.name == "GeneratorFunction"
      fn = async fn
      fn(context)
      .then -> context.pass()
      .catch (error) -> context.fail error
    else
      try
        fn()
        context.pass()
      catch error
        context.fail error

  pass: ->
    @result = true
    Context.finish()

  fail: (error) ->
    @result = true
    @error = error
    Context.finish()

  report: ->

    console.log if @result?
      if @error?
        "#{@description} #{inspect(@error)}".red
      else
        color = (if @result then "green" else "yellow")
        @description[color]
    else if @description?
      @description.bold.green

    kid.report() for kid in @kids


module.exports = do ->

  process.on "exit", ->
    if Context.pending > 0
      console.error "warning: #{Context.pending} tests still pending"
    Context.root?.report()

  Context
