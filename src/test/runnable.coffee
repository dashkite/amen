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

        if result?
          if isThenable result
            await timeout @options.wait, result
          else if isIterable result
            undefined for value from result
          else if isReactive result
            await timeout @options.wait, do ->
              undefined for await value from result
              undefined

        @_pass true
      catch error
        @_fail error

export { RunnableTest }
export default RunnableTest
