global.$p ?= -> console.log arguments...

assert = require "assert"
colors = require "colors"
{empty, promise, isPromise, lift, async, include, isType} = require "fairmont"

Context =

  create: (description, parent) ->

    context = {description, parent, kids: [], root: parent.root}

    include context,

      test: async (description, f) ->
        parent = context
        g = (async f) if f?
        child = Context.create description, parent
        parent.kids.push child

        if g?
          child.start()
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
          if !(isType assert.AssertionError, error)
            console.error error.stack

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
                report root.context

        root.context = Context.create description, {root}
        f root.context

      catch error
        console.error error.stack
        report root.context

  report: report = (context, indent = "") ->

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
    (report kid, indent) for kid in kids

module.exports = Context
