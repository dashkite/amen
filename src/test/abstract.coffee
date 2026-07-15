import { once } from "@dashkite/joy"

class AbstractTest
  constructor: ->
    @status = "pending"
    @run = once @run
    @promise = new Promise ( resolve, reject ) =>
      @_resolve = resolve
      @_reject = reject





  [ Symbol.asyncIterator ]: ->
    iterator = @_iterate()
    iterator.test = @
    iterator

  _fail: ( error ) ->
    @status = "failed"
    @error = error
    @_resolve @
    @promise

  _pass: ->
    @status = "passed"
    @_resolve @
    @promise

  _iterate: ->
    if @description?
      runPromise = @run()
      yield type: "test:start", test: @
      await runPromise
      switch @status
        when "passed"
          yield type: "test:success", test: @
        when "failed"
          yield type: "test:failure", test: @, error: @error
        when "skipped"
          yield type: "test:skipped", test: @
        else
          yield type: "test:pending", test: @
    else
      yield from []

export { AbstractTest }
export default AbstractTest
