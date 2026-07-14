import assert from "@dashkite/assert"
import { test } from "stable-amen"
import print from "stable-amen-console"
import {
  AbstractTest
  TestGroup
  RunnableTest
  PendingTest
  ComputedTest
  test as localTest
} from "../src/test/index"

delay = ( ms ) -> new Promise ( resolve ) -> setTimeout resolve, ms

do ->
  suite = test "Amen Test Coverage", [

    test "Generic Dispatcher routes correctly", ->
      assert ( localTest "desc" ) instanceof PendingTest
      assert ( localTest description: "desc" ) instanceof PendingTest

      assert ( localTest "desc", {} ) instanceof PendingTest
      assert ( localTest "desc", ( -> true ) ) instanceof RunnableTest
      assert ( localTest "desc", [] ) instanceof TestGroup
      assert ( localTest "desc", Promise.resolve true ) instanceof ComputedTest

      assert ( localTest { description: "desc" }, ( -> true ) ) instanceof RunnableTest
      assert ( localTest { description: "desc" }, [] ) instanceof TestGroup
      assert ( localTest { description: "desc" }, Promise.resolve true ) instanceof ComputedTest

      assert ( localTest "desc", {}, ( -> true ) ) instanceof RunnableTest
      assert ( localTest "desc", {}, [] ) instanceof TestGroup
      assert ( localTest "desc", {}, Promise.resolve true ) instanceof ComputedTest

    test "ComputedTest behavior", [

      test "valid boolean resolves", ->
        node = ComputedTest.make true
        result = await node
        assert.equal result, true

      test "valid Promise resolves", ->
        node = ComputedTest.make ( Promise.resolve "hello" )
        result = await node
        assert.equal result, "hello"

      test "invalid type throws asynchronously inside run()", ->
        node = ComputedTest.make 123
        result = await node
        assert.equal node.status, "failed"
        assert /Invalid test definition/.test node.error.message

      test "ComputedTest result shaping (named vs anonymous)", ->
        anon = ComputedTest.make true
        assert.equal ( await anon ), true

        named = ComputedTest.make "named test", true
        assert.equal ( await named )[ 0 ], "named test"
        assert.equal ( await named )[ 1 ], true
    ]

    test "RunnableTest timeout behavior", [

      test "resolves before timeout passes", ->
        node = RunnableTest.make "fast", ( -> delay 10 ), wait: 50
        await node
        assert.equal node.status, "passed"

      test "runs longer than timeout fails", ->
        node = RunnableTest.make "slow", ( -> delay 50 ), wait: 10
        await node
        assert.equal node.status, "failed"
        assert /Test timed out/.test node.error.message
    ]

    test "RunnableTest definition execution variants", [

      test "sync function", ->
        node = RunnableTest.make "sync", -> "done"
        await node
        assert.equal node.status, "passed"

      test "promise/async function", ->
        node = RunnableTest.make "promise", -> Promise.resolve "done"
        await node
        assert.equal node.status, "passed"

      test "sync generator function", ->
        node = RunnableTest.make "generator", ->
          yield 1
          yield 2
        await node
        assert.equal node.status, "passed"

      test "async generator function", ->
        node = RunnableTest.make "async generator", ->
          yield await Promise.resolve 1
          yield await Promise.resolve 2
        await node
        assert.equal node.status, "passed"
    ]
  ]

  results = await suite
  await print results

  # Reset process.exitCode if the coverage suite successfully passed,
  # as the intentional subclass failures inside the assertions will have set it to 1.
  if process? && ( suite.status != "failed" )
    process.exitCode = 0
