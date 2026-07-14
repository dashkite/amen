import { AbstractTest } from "./abstract"

class PendingTest extends AbstractTest
  @make: ( description, options = {} ) ->
    Object.assign ( new @ ), { description, options }

  run: ->
    @status = "pending"
    @result = [ @description, undefined ]
    @_resolve @result
    @promise

export { PendingTest }
export default PendingTest
