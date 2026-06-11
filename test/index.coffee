import { fork } from "child_process"
import { fileURLToPath } from "url"
import { dirname, join } from "path"
import assert from "@dashkite/assert"
import { test, print } from "../src"

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

  print await test "Amen Test Runner", [

    test "passing suite exits with 0", ->
      { code } = await run "passing"
      assert.equal code, 0

    test "failing suite exits with 1 and prints expected errors", ->
      { code, stderr } = await run "failing"
      assert.equal code, 1
      assert ( stderr.includes "oops" )
      assert ( stderr.includes "failing test" )
      assert ( stderr.includes "Invalid test definition" )

  ]
