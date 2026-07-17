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

  apply: ->
    if ! shouldRun @
      @status = "skipped"
    else
      result = @definition.call @

      resolvedValue = if isThenable result
        await timeout @options.wait, result
      else if isIterable result
        for value from result
          undefined
        undefined
      else if isReactive result
        await timeout @options.wait, ( do ->
          for await value from result
            undefined
          undefined
        )
      else
        result

      if resolvedValue == Symbol.for "skipped"
        @status = "skipped"
      else if resolvedValue == Symbol.for "pending"
        @status = "pending"

export { RunnableTest }
export default RunnableTest
