import {print, test} from "../src/amen"
import assert from "assert"
import {sleep} from "fairmont-helpers"

alwaysTrue = -> assert true
sleepyTrue = ->
  await sleep 2000
  assert true

console.log "-".repeat 80
console.log """
 IMPORTANT
 Custom Timeout tests should generate three timeout errors.
"""
console.log "-".repeat 80

Test = ->
  print await test "Setting custom timeouts", [
    test "A passing test with default timeout", alwaysTrue
    test "A passing test with 500ms timeout", alwaysTrue, 500

    test "A failing test with default timeout", sleepyTrue
    test "A failing test with 500ms timeout", sleepyTrue, 500
    test "A passing test with 2500ms timeout", sleepyTrue, 2500

    test "A set of passing, nested tests that finish in time", [
      test "nest 1", alwaysTrue
      test "nest 2", alwaysTrue
      test "nest 3", alwaysTrue
    ], 1000

    test "A set of nested tests that don't finish in time", [
      test "nest 1", alwaysTrue
      test "nest 2", alwaysTrue
      test "nest 3", sleepyTrue
    ], 1000

  ]

export default Test
