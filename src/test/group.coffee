import { ReactorQueue } from "@dashkite/river"
import { AbstractTest } from "./abstract"
import { ComputedTest } from "./computed"

concurrentMerge = ( iterators ) ->
  queue = ReactorQueue.make()
  active = iterators.length

  for iterator in iterators
    do ( iterator ) ->
      try
        loop
          { value, done } = await iterator.next()
          if value?
            queue.enqueue value
          if done
            break
      catch error
        queue.enqueue type: "test:failure", test: iterator.test, error: error
      finally
        active--
        if active == 0
          queue.close()

  queue

class TestGroup extends AbstractTest
  @make: ( description, definition, options = {} ) ->
    instance = Object.assign ( new @ ), { description, definition, options }
    instance.children = []
    for child from definition
      node = if child instanceof AbstractTest then child else ComputedTest.make child
      node.parent = instance
      instance.children.push node
    instance

  run: ->
    @status = "running"
    try
      childResults = await Promise.all ( child.run() for child in @children )
      @status = "passed"
      @result = [ @description, childResults ]
      @_resolve @result
      @promise
    catch error
      if process?
        process.exitCode = 1
      @status = "failed"
      @error = error
      @result = [ @description, { success: false, message: error.message, stack: error.stack } ]
      @_resolve @result
      @promise

  _iterate: ->
    runPromise = @run()
    yield type: "group:start", test: @
    childrenIterators = ( child[ Symbol.asyncIterator ]() for child in @children )
    yield from concurrentMerge childrenIterators
    await runPromise
    yield type: "group:end", test: @

export { TestGroup }
export default TestGroup
