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

    test "targeting tests", [
      test "tag targeting options filter tests", ->
        suite = test "targeted suite", { active: "deploy" }, [
          test "deploy test", { targets: [ "deploy" ] }, -> true
          test "other test", { targets: [ "other" ] }, -> true
          test "untargeted test", -> true
        ]

        await suite.run()

        assert.equal suite.children[0].status, "passed"
        assert.equal suite.children[1].status, "skipped"
        assert.equal suite.children[2].status, "skipped"

      test "hierarchical tag targeting requires all targeted lineage nodes to match", ->
        suite = test "hierarchical suite", {
          active: [ "validate", "blog-platform" ]
        }, [
          test "blog-platform", { targets: "blog-platform" }, [
            test "compilation", { targets: "compile" }, -> true
            test "validation", { targets: "validate" }, -> true
          ]
          test "ecommerce-storefront", { targets: "ecommerce-storefront" }, [
            test "compilation", { targets: "compile" }, -> true
            test "validation", { targets: "validate" }, -> true
          ]
        ]

        await suite.run()

        blog = suite.children[0]
        ecommerce = suite.children[1]
        assert.equal blog.children[0].status, "skipped"
        assert.equal blog.children[1].status, "passed"
        assert.equal ecommerce.children[0].status, "skipped"
        assert.equal ecommerce.children[1].status, "skipped"

      test "targeting by description name", ->
        suite = test "name suite", [
          test "run special feature", -> true
          test "run standard feature", -> true
        ]
        suite.active = "special"

        await suite.run()

        assert.equal suite.children[0].status, "passed"
        assert.equal suite.children[1].status, "skipped"

      test "targeting untargeted leaf by description inside targeted group", ->
        suite = test "mixed suite", { active: "Computes" }, [
          test "Hasher", { targets: "#integration" }, [
            test "Computes deterministic SHA-256", -> true
            test "Handles empty directory", -> true
          ]
        ]

        await suite.run()

        hasher = suite.children[0]
        assert.equal hasher.children[0].status, "passed"
        assert.equal hasher.children[1].status, "skipped"

      test "unnamed group and array chaining with .and", ->
        order = []
        unnamed = test [
          test "parallel a", -> order.push "a"
          test "parallel b", -> order.push "b"
        ]
        await unnamed.run()
        assert.equal unnamed.children[0].status, "passed"
        assert.equal unnamed.children[1].status, "passed"

        first = test "prerequisite", ->
          throw new Error "prerequisite failed"
        secondA = test "dependent a", -> true
        secondB = test "dependent b", -> true
        chain = first.and [ secondA, secondB ]

        await chain.run()
        assert.equal first.status, "failed"
        assert.equal secondA.status, "skipped"
        assert.equal secondB.status, "skipped"

      test "target-tagged .before and .after hooks filter by active targets", ->
        # 1. When active is [ "validate" ], deploy/undeploy hooks are skipped while unconditional hooks run
        events = []
        validateOnly = ( test "validate-only suite", { active: [ "validate" ] }, [
          test "check", { targets: "validate" }, -> events.push "validate"
        ])
          .before -> events.push "always-before"
          .before { targets: "deploy" }, -> events.push "deploy"
          .after { targets: "undeploy" }, -> events.push "undeploy"
          .after -> events.push "always-after"

        await validateOnly.run()
        assert.deepEqual events, [ "always-before", "validate", "always-after" ]

        # 2. When active includes deploy, validate, and undeploy (CI mode), all hooks run in lifecycle order
        ciEvents = []
        ciSuite = ( test "ci suite", { active: [ "deploy", "validate", "undeploy" ] }, [
          test "check", { targets: "validate" }, -> ciEvents.push "validate"
        ])
          .before { targets: "deploy" }, -> ciEvents.push "deploy"
          .after { targets: "undeploy" }, -> ciEvents.push "undeploy"

        await ciSuite.run()
        assert.deepEqual ciEvents, [ "deploy", "validate", "undeploy" ]

        # 3. Standalone deploy or undeploy target runs only the matching hook
        deployEvents = []
        deployOnly = ( test "deploy-only suite", { active: "deploy" }, [
          test "check", { targets: "validate" }, -> deployEvents.push "validate"
        ])
          .before { targets: "deploy" }, -> deployEvents.push "deploy"
          .after { targets: "undeploy" }, -> deployEvents.push "undeploy"

        await deployOnly.run()
        assert.deepEqual deployEvents, [ "deploy" ]
        assert.equal deployOnly.children[ 0 ].status, "skipped"

        # 4. Async iteration (for await / print) waits for async .before hooks before starting children
        streamEvents = []
        streamed = ( test "streamed suite", { active: [ "deploy", "validate", "undeploy" ] }, [
          test "child check", { targets: "validate" }, ->
            streamEvents.push "validate"
        ])
          .before { targets: "deploy" }, ->
            await new Promise ( resolve ) -> setTimeout resolve, 25
            streamEvents.push "deploy"
          .after { targets: "undeploy" }, ->
            await new Promise ( resolve ) -> setTimeout resolve, 10
            streamEvents.push "undeploy"

        for await event from streamed
          undefined
        assert.deepEqual streamEvents, [ "deploy", "validate", "undeploy" ]

        # 5. Group .before and .after hook errors emit test:failure events and record _hookError
        beforeFailed = ( test "failing before group", [
          test "unreached child", -> assert true
        ])
          .before -> throw new Error "deploy boom"

        beforeYielded = []
        for await event from beforeFailed
          beforeYielded.push event.type
        assert.equal beforeFailed.status, "failed"
        assert.equal beforeFailed._hookError?.message, "deploy boom"
        assert "test:failure" in beforeYielded
    ]
  ]
