import { isThenable } from "@dashkite/joy"
import { AbstractTest } from "./abstract"

class ComputedTest extends AbstractTest
  @make: ( args... ) ->
    if args.length == 1
      Object.assign ( new @ ), { value: args[ 0 ] }
    else
      [ description, value, options ] = args
      Object.assign ( new @ ), { description, value, options }

  run: ->
    @status = "running"
    try
      if ( @value? ) &&
         ( ! isThenable @value ) &&
         ( typeof @value != "boolean" ) &&
         ( ! Array.isArray @value )
        throw new Error "Invalid test definition"

      resolvedValue = if isThenable @value then await @value else @value
      @status = "passed"
      @result = if @description? then [ @description, resolvedValue ] else resolvedValue
      @_resolve @result
      @promise
    catch error
      if process?
        process.exitCode = 1
      @status = "failed"
      @error = error
      failureResult = { success: false, message: error.message, stack: error.stack }
      @result = if @description? then [ @description, failureResult ] else failureResult
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

export { ComputedTest }
export default ComputedTest
