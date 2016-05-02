global.$p ?= -> console.log arguments...

assert = require "assert"
colors = require "colors"
F = require "fairmont"
{empty, include} = F
{isType, isPromise, isGeneratorFunction} = F
{promise, lift, async, call} = F

hoist = (f) -> if isGeneratorFunction f then async f else f

Context =

  create: (description, parent) ->

    context = {description, parent, kids: [], root: parent.root}

    include context,

      test: (description, f) ->

        parent = context
        child = Context.create description, parent
        parent.kids.push child

        if (g = hoist f)?
          child.start()
          call ->
            try
              yield g child
              child.pass()
            catch error
              child.fail error

      describe: -> context.test arguments...

      pass: ->
        context.finish()
        context.result = true

      fail: (error) ->
        context.finish()
        context.result = false
        if error?
          context.error = error
          unless isType assert.AssertionError, error
            context.root.errors.push error

      start: context.root.start

      finish: context.root.finish

  describe: (description, f) ->

    promise (resolve, reject) ->

      try

        pending = 0
        root =

          start: -> ++pending

          finish: ->
            setImmediate ->
              if --pending == 0
                resolve()
                report root

          errors: []

        root.context = Context.create description, {root}
        f root.context

      catch error
        console.error error.stack
        report root

report = ({context, errors}) ->

  do _report = (context, indent = "") ->

    {description, result, error, parent, root, kids} = context

    console.log indent,

      if result?

        if result
          description.green
        else if error?
          "#{description} #{error}".red
        else
          description.red

      else

        if empty kids
          description.yellow
        else
          description.green

    indent += "  "
    (_report kid, indent) for kid in kids

  setImmediate ->
    console.error "\n" + error.stack for error in errors



module.exports = Context
