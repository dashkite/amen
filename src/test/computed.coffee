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
      @_pass resolvedValue
    catch error
      @_fail error

export { ComputedTest }
export default ComputedTest
