#
# This is a bit of an experiment. I love the simplicity of the Testify
# interface. However, I wanted to see if I could simplify the implementation
# to make it a bit easier to hack on. It seemed to me that a stack-based
# approach using closures would be easier to reason about than the FSA
# model that Testify uses. At < 100 LoC, I think so far the results are
# encouraging, although Testify has a lot more features.
#

assert = require "assert"
colors = require "colors"
{inspect} = require "util"

class Context

  constructor: (@description, @parent) ->
    @kids = []

  push: (description) ->
    context = new Context(description, @)
    @kids.push(context)
    context


  pop: -> @parent

  describe: (description, fn) ->
    fn(@push description)

  test: (description, fn) ->
    context = @push (description)
    try
      context.start()
      if fn.length > 0
        do ->
          fn(context)
      else
        fn()
        context.pass()
    catch error
      context.fail(error)

  start: -> Context.pending++
  finish: -> Context.pending--

  pass: (assert) ->
    try
      assert?()
      @result = true
    catch error
      @fail error
    @finish()

  fail: (error) ->
    @error = error
    @result = false
    @finish()

  report: ->
    if @result?
      if @error?
        console.log "#{@description} #{inspect(@error)}".red
      else
        color = (if @result then "green" else "yellow")
        console.log @description[color]
    else if @description?
      console.log @description.bold.green

  summarize: ->
    @report()
    kid.summarize() for kid in @kids


module.exports = do ->

  process.on "exit", ->
    root.summarize()

  root = new Context()
