assert = require "assert"
amen = require "../src/amen"

amen.describe "Using Amen to test itself", (context) ->

  context.test "A simple test", -> assert true
