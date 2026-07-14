import { once } from "@dashkite/joy"

class AbstractTest
  constructor: ->
    @status = "pending"
    @run = once @run
    @promise = new Promise ( resolve, reject ) =>
      @_resolve = resolve
      @_reject = reject
      queueMicrotask =>
        if ( ! @parent? ) && ( @status == "pending" )
          @run()

  then: ( onFulfilled, onRejected ) ->
    @promise.then onFulfilled, onRejected

  catch: ( onRejected ) ->
    @promise.catch onRejected

  [ Symbol.asyncIterator ]: ->
    iterator = @_iterate()
    iterator.test = @
    iterator

  _fail: ( error ) ->
    if process?
      process.exitCode = 1
    @status = "failed"
    @error = error
    failureResult = { success: false, message: error.message, stack: error.stack }
    @result = if @description? then [ @description, failureResult ] else failureResult
    @_resolve @result
    @promise

  _pass: ( value ) ->
    @status = "passed"
    @result = if @description? then [ @description, value ] else value
    @_resolve @result
    @promise

  _iterate: ->
    if @description?
      runPromise = @run()
      yield type: "test:start", test: @
      await runPromise
      switch @status
        when "passed" then yield type: "test:success", test: @
        when "failed" then yield type: "test:failure", test: @, error: @error
        when "skipped" then yield type: "test:skipped", test: @
        else yield type: "test:pending", test: @
    else
      yield from []

export { AbstractTest }
export default AbstractTest
