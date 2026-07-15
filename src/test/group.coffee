import { ReactorQueue } from "@dashkite/river"
import { AbstractTest } from "./abstract"
import { ComputedTest } from "./computed"

concurrentMerge = ( iterables ) ->
  queue = ReactorQueue.make()
  active = iterables.length

  for iterable in iterables
    do ( iterable ) ->
      try
        for await value from iterable
          queue.enqueue value
      catch error
        queue.enqueue type: "test:failure", test: iterable, error: error
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
      node =
        if child instanceof AbstractTest
          child
        else
          ComputedTest.make child
      node.parent = instance
      instance.children.push node
    instance

  run: ->
    @status = "running"
    try
      childResults = await Promise.all ( child.run() for child in @children )
      @_pass childResults
    catch error
      @_fail error

  _iterate: ->
    runPromise = @run()
    yield type: "group:start", test: @
    try
      yield from concurrentMerge @children
    catch error
      if error.message != "queue closed with pending items"
        throw error
    await runPromise
    yield type: "group:end", test: @

export { TestGroup }
export default TestGroup
