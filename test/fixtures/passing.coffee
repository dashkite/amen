import assert from "@dashkite/assert"
import { test, print } from "../../src"

do ->
  await print await test "passing fixture", [
    test "simple pass", ->
      assert.equal ( 1 + 1 ), 2
    test "nested pass", [
      test "nested", ->
        assert.equal true, true
    ]
  ]

