import { once } from "@dashkite/joy"

class AbstractTest
  constructor: ->
    @status = "pending"
    @run = once @run
    @promise = new Promise ( resolve, reject ) =>
      @_resolve = resolve
      @_reject = reject
    @_before = []
    @_after = []

  before: ( callback ) ->
    @_before.push callback
    @

  after: ( callback ) ->
    @_after.push callback
    @

  run: ->
    if @status == "skipped"
      @_resolve @
      @promise
    else
      @status = "running"
      try
        for hook in @_before
          await hook.call @
        
        await @apply()
        
        if @status == "running"
          @_pass()
      catch error
        @_fail error
      finally
        for hook in @_after
          try
            await hook.call @
          catch hookError
            @_fail hookError





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

  count: ->
    if @description?
      1
    else
      0

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
