import { fork } from "child_process"
import { fileURLToPath } from "url"
import { dirname, join } from "path"
import assert from "@dashkite/assert"
import { test, print } from "../src"
import "./coverage"

filename = fileURLToPath import.meta.url
directory = dirname filename

run = ( name ) ->
  new Promise ( resolve ) ->
    path = join directory, "fixtures", "#{ name }.js"
    child = fork path, [], stdio: "pipe"
    
    stdout = ""
    stderr = ""
    
    child.stdout.on "data", ( data ) -> stdout += data.toString()
    child.stderr.on "data", ( data ) -> stderr += data.toString()
    
    child.on "exit", ( code ) ->
      resolve { code, stdout, stderr }

do ->

  await print test "Amen Test Runner", [

    test "passing suite exits with 0", ->
      { code } = await run "passing"
      assert.equal code, 0

    test "failing suite exits with 1 and prints expected errors", ->
      { code, stderr } = await run "failing"
      assert.equal code, 1
      assert ( stderr.includes "oops" )
      assert ( stderr.includes "failing test" )
      assert ( stderr.includes "Invalid test definition" )

    test "async iterator yields events in real-time", ->
      events = []
      suite = test "sub-suite", [
        test "test A", -> new Promise (resolve) -> setTimeout resolve, 10
        test "test B", -> true
      ]
      
      # We must run it to generate events
      runPromise = suite.run()
      
      for await event from suite
        events.push type: event.type, description: event.test.description
        
      await runPromise
      
      assert.deepEqual events, [
        { type: "group:start", description: "sub-suite" }
        { type: "test:start", description: "test A" }
        { type: "test:start", description: "test B" }
        { type: "test:success", description: "test B" }
        { type: "test:success", description: "test A" }
        { type: "group:end", description: "sub-suite" }
      ]

    test "print supports iterator interface for live printing", ->
      suite = test "live print sub-suite", [
        test "test C", -> true
      ]
      await print suite

    test "iterable support for group definition", ->
      suite = test "set suite", new Set [
        test "test in set", -> true
      ]
      
      await suite.run()
      assert.equal suite.children[0].status, "passed"

    test "targeting tests", ->
      await test "tag targeting options filter tests", ->
        suite = test "targeted suite", { active: "deploy" }, [
          test "deploy test", { targets: ["deploy"] }, -> true
          test "other test", { targets: ["other"] }, -> true
          test "untargeted test", -> true
        ]
        
        await suite.run()
        
        assert.equal suite.children[0].status, "passed"
        assert.equal suite.children[1].status, "skipped"
        assert.equal suite.children[2].status, "skipped"

      await test "targeting by description name", ->
        suite = test "name suite", [
          test "run special feature", -> true
          test "run standard feature", -> true
        ]
        suite.active = "special"
        
        await suite.run()
        
        assert.equal suite.children[0].status, "passed"
        assert.equal suite.children[1].status, "skipped"
  ]
