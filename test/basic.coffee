import {print, test} from "../src/amen"
import assert from "assert"

promise = (resolve, reject) -> new Promise resolve, reject

good = -> promise (resolve) -> setTimeout resolve, 100
bad = -> promise (_, reject) -> setTimeout (-> reject new Error "oops"), 100

console.log "-".repeat 80
console.log " IMPORTANT\n Basic tests should generate an error ('oops')
              and have three failing tests\n and a pending test."
console.log "-".repeat 80

Test = ->
  print await test "Start with the basics", [
    test "A simple test", -> assert true
    test "A nested test", [
      test "I'm nested", -> assert true
    ]
    test "A failing test", -> assert false
    test "A nested group of async tests", [
      test "An async test", -> await good()
      test "A failing async test", -> await bad()
      test "An async test that never resolves", -> (promise ->)
    ]
    test "A pending test"
  ]

export default Test
