import { AbstractTest } from "./abstract"
import { chainable } from "./chainable"
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

class RunnableTest extends chainable AbstractTest
  @make: ( description, definition, options = {} ) ->
    Object.assign ( new @ ), { description, definition, options }

  run: ->
    if @status == "skipped"
      @_resolve @
      @promise
    else
      @status = "running"
      if ! shouldRun @
        @status = "skipped"
        @_resolve @
        @promise
      else
        try
          result = @definition.call @

          resolvedValue = undefined
          if isThenable result
            resolvedValue = await timeout @options.wait, result
          else if isIterable result
            undefined for value from result
          else if isReactive result
            resolvedValue = await timeout @options.wait, do ->
              undefined for await value from result
              undefined
          else
            resolvedValue = result

          if resolvedValue == Symbol.for "skipped"
            @status = "skipped"
          else if resolvedValue == Symbol.for "pending"
            @status = "pending"

          if @status == "running"
            @_pass()
          else
            @_resolve @
            @promise
        catch error
          @_fail error

export { RunnableTest }
export default RunnableTest
