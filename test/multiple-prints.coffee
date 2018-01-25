import {print, test} from "../src/amen"
import assert from "assert"

Test = ->
  print await test
    description: "Allow Multiple Prints"
    wait: false
    ->
      print await test "First Nested Print", [
        test "test 1", -> assert true
        test "test 2", -> assert true
      ]

      print await test "Second Nested Print", [
        test "test 3", -> assert true
        test "test 4", -> assert true
      ]

export default Test
