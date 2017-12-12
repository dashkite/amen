import {print, test} from "../src/amen"
import assert from "assert"

timer = (wait, action) -> setTimeout(action, wait)

sleep = (interval) ->
  new Promise (resolve, reject) ->
    timer interval, -> resolve()

sleepyTrue = ->
  await sleep 150
  assert true

console.log "-".repeat 80
console.log """
 IMPORTANT
 Custom Timeout tests should generate one pass and one timeout error.
"""
console.log "-".repeat 80

Test = ->
  print await test "Setting custom timeouts", [
    test
      description: "A passing test with 200ms timeout"
      wait: 200,
      sleepyTrue

    test
      description: "A failing test with 50ms timeout"
      wait: 50,
      sleepyTrue
  ]

export default Test
