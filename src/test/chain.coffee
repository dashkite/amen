import { isIterable, isString } from "@dashkite/joy"
import { AbstractTest } from "./abstract"
import { TestGroup } from "./group"

normalize = ( step ) ->
  if step instanceof AbstractTest
    step
  else if ( isIterable step ) && !( isString step )
    TestGroup.make undefined, step
  else
    throw new Error "and: argument must be an instance of AbstractTest"

class TestChain extends AbstractTest
  constructor: ( first, second ) ->
    super()
    target = normalize second
    @children = [ first, target ]
    first.parent = @
    target.parent = @

  and: ( resolve ) ->
    target = normalize resolve
    target.parent = @
    @children.push target
    @

  count: ->
    sum = 0
    for child in @children
      sum += child.count()
    sum

  _skip: ->
    for child in @children
      child._skip()
    super()

  apply: ->
    failed = false
    aborted = false
    for child in @children
      if aborted
        await child._skip()
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
    await @_ready
    if @_beforeError?
      yield type: "test:failure", test: @, error: @_beforeError
    else
      for child in @children
        for await event from child
          yield event
        
    await runPromise
    if @_afterError?
      yield type: "test:failure", test: @, error: @_afterError
    
    if @description?
      yield type: "group:end", test: @

export { TestChain }
export default TestChain
