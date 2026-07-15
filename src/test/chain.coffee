import { AbstractTest } from "./abstract"

class TestChain extends AbstractTest
  constructor: ( first, second ) ->
    super()
    @children = [ first, second ]
    first.parent = @
    second.parent = @

  and: ( resolve ) ->
    if resolve instanceof AbstractTest
      resolve.parent = @
      @children.push resolve
      @
    else
      throw new Error "and: argument must be an instance of AbstractTest"

  run: ->
    @status = "running"
    try
      failed = false
      aborted = false
      for child in @children
        if aborted
          child.status = "skipped"
          child._resolve child
          await child.promise
        else
          await child.run()
          if child.status == "failed"
            failed = true
            aborted = true
          else if child.status == "skipped"
            aborted = true
      if failed
        @_fail new Error "Chain failed"
      else
        @_pass()
    catch error
      @_fail error

  _iterate: ->
    if @description?
      yield type: "group:start", test: @
    
    runPromise = @run()
    for child in @children
      for await event from child
        yield event
        
    await runPromise
    
    if @description?
      yield type: "group:end", test: @

export { TestChain }
export default TestChain
