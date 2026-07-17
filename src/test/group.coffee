import { ReactorQueue } from "@dashkite/river"
import { AbstractTest } from "./abstract"
import { chainable } from "./chainable"

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

class TestGroup extends chainable AbstractTest
  @make: ( description, definition, options = {} ) ->
    instance = Object.assign ( new @ ), { description, definition, options }
    instance.children = []
    for child from definition
      unless child instanceof AbstractTest
        throw new Error "Invalid child test: must be an instance of AbstractTest"
      child.parent = instance
      instance.children.push child
    instance

  count: ->
    sum = 0
    for child in @children
      sum += child.count()
    sum

  apply: ->
    await Promise.all ( child.run() for child in @children )

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
