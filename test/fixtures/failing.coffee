import assert from "@dashkite/assert"
import { test, print } from "../../src"

do ->
  await print await test "failing fixture", [
    test "failing test", ->
      throw new Error "failing test"
    test "failing async test", ->
      new Promise ( _, reject ) ->
        setTimeout (-> reject new Error "oops"), 10
    test "invalid definition", 123
  ]

