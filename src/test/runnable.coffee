import { AbstractTest } from "./abstract"
import { shouldRun } from "../targets"
import {
  isIterable
  isReactive
  isThenable
} from "@dashkite/joy"

timeout = ( wait, promise ) ->
  if wait?
    new Promise ( resolve, reject ) ->
      timer = setTimeout ( -> reject new Error "Test timed out" ), wait
      try
        resolve await promise
      catch error
        reject error
      finally
        clearTimeout timer
  else
    promise

class RunnableTest extends AbstractTest
  @make: ( description, definition, options = {} ) ->
    Object.assign ( new @ ), { description, definition, options }

  run: ->
    @status = "running"
    if ! shouldRun @
      @status = "skipped"
      @result = [ @description, undefined ]
      @_resolve @result
      @promise
    else
      try
        result = @definition()

        if isThenable result
          await timeout @options.wait, result
        else if isIterable result
          undefined for value from result
        else if isReactive result
          await timeout @options.wait, do ->
            undefined for await value from result
            undefined

        @status = "passed"
        @result = [ @description, true ]
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
    yield type: "test:start", test: @
    await runPromise
    switch @status
      when "passed" then yield type: "test:success", test: @
      when "failed" then yield type: "test:failure", test: @, error: @error
      when "skipped" then yield type: "test:skipped", test: @
      else yield type: "test:pending", test: @

export { RunnableTest }
export default RunnableTest
