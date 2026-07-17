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

  count: ->
    sum = 0
    for child in @children
      sum += child.count()
    sum

  apply: ->
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
      throw new Error "Chain failed"

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
