import assert from "@dashkite/assert"
import { test } from "stable-amen"
import print from "stable-amen-console"
import {
  AbstractTest
  TestGroup
  RunnableTest
  PendingTest
  TestChain
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

      assert ( localTest { description: "desc" }, ( -> true ) ) instanceof RunnableTest
      assert ( localTest { description: "desc" }, [] ) instanceof TestGroup

      assert ( localTest "desc", {}, ( -> true ) ) instanceof RunnableTest
      assert ( localTest "desc", {}, [] ) instanceof TestGroup

    test "TestChain behavior", [

      test "creates and extends a TestChain using .and()", ->
        a = RunnableTest.make "a", ->
        b = RunnableTest.make "b", ->
        c = RunnableTest.make "c", ->
        
        chain = a.and(b).and(c)
        assert chain instanceof TestChain
        assert.equal chain.children.length, 3
        assert.equal chain.children[0], a
        assert.equal chain.children[1], b
        assert.equal chain.children[2], c

      test "executes chained tests sequentially", ->
        order = []
        a = RunnableTest.make "a", ->
          await delay 10
          order.push 1
        b = RunnableTest.make "b", ->
          order.push 2
          
        chain = a.and(b)
        await chain.run()
        assert.deepEqual order, [ 1, 2 ]
    ]

    test "RunnableTest timeout behavior", [

      test "resolves before timeout passes", ->
        node = RunnableTest.make "fast", ( -> delay 10 ), wait: 50
        await node.run()
        assert.equal node.status, "passed"

      test "runs longer than timeout fails", ->
        node = RunnableTest.make "slow", ( -> delay 50 ), wait: 10
        await node.run()
        assert.equal node.status, "failed"
        assert /Test timed out/.test node.error.message
    ]

    test "RunnableTest definition execution variants", [

      test "sync function", ->
        node = RunnableTest.make "sync", -> true
        await node.run()
        assert.equal node.status, "passed"

      test "promise/async function", ->
        node = RunnableTest.make "async", -> Promise.resolve true
        await node.run()
        assert.equal node.status, "passed"

      test "sync generator function", ->
        executed = false
        node = RunnableTest.make "generator", ->
          yield executed = true
        await node.run()
        assert.equal node.status, "passed"
        assert.equal executed, true

      test "async generator function", ->
        executed = false
        node = RunnableTest.make "async generator", ->
          yield await Promise.resolve( executed = true )
        await node.run()
        assert.equal node.status, "passed"
        assert.equal executed, true
    ]
  ]

  # Run the coverage suite using stable-amen and stable-amen-console
  print await suite
