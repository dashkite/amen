assert = require "assert"
amen = require "../src/amen"
{promise} = require "when"

# Two very contrived async functions...

good = -> promise (resolve) -> setTimeout resolve, 100

bad = ->
  promise (resolve, reject) ->
    setTimeout (-> reject new Error "oops"), 100

amen.describe "Using Amen to test itself", (context) ->

  context.test "A simple test", -> assert true

  context.test "A nested test", (context) ->

    context.test "I'm nested!", -> assert true

  context.test "A failing test", -> assert false

  context.describe "A nested group of tests", (context) ->

    context.test "An asynchronous test", -> yield good()

    context.test "A failing asynchronous test", -> yield bad()

  context.test "A pending test"
