import assert from "assert"
import {print, test, success} from "../src"

# import customTimeout from "./custom-timeout"
# import multiple from "./multiple-prints"

promise = (resolve, reject) -> new Promise resolve, reject

good = -> promise (resolve) -> setTimeout resolve, 100
bad = -> promise (_, reject) -> setTimeout (-> reject new Error "oops"), 100

timer = (wait, action) -> setTimeout(action, wait)

sleep = (interval) ->
  new Promise (resolve, reject) ->
    timer interval, -> resolve()

sleepyTrue = ->
  await sleep 150
  assert true

indent = (s) -> ("  #{line}" for line in s.split "\n").join "\n"
border = "-".repeat 80
banner = (s) -> console.log "#{border}\n#{indent s}\n#{border}"

do ->
  print await test "Using Amen to test itself", [
    test
      description: "Basic Tests"
      wait: false,
      [
        test "Start with the basics", [
          test "A simple test", ->
          test "A nested test", [
            test "I'm nested", ->
          ]
          test "A failing test", -> assert false
          test "A nested group of async tests", [
            test "An async test", -> await good()
            test "A failing async test", -> await bad()
            test "An async test that never resolves", -> (promise ->)
          ]
          test "A pending test"
        ]
      ]

    test
      description: "Custom Timeout"
      wait: false,
      [
        test
          description: "A passing test with 200ms timeout"
          wait: 200,
          sleepyTrue

        test
          description: "A failing test with 50ms timeout"
          wait: 50,
          sleepyTrue
      ]
  ]

  banner """

    IMPORTANT

    Basic tests should generate an error ('oops')
    and have three failing tests and a pending test.

    Custom Timeout tests should generate one pass
    and one timeout error.

    Tests should exit with a non-zero status code.

  """

  process.exit if success then 0 else 1
