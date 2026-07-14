import { AbstractTest } from "./abstract"

class PendingTest extends AbstractTest
  @make: ( description, options = {} ) ->
    Object.assign ( new @ ), { description, options }

  run: ->
    @status = "pending"
    @result = [ @description, undefined ]
    @_resolve @result
    @promise

  _iterate: ->
    runPromise = @run()
    yield type: "test:start", test: @
    await runPromise
    yield type: "test:pending", test: @

export { PendingTest }
export default PendingTest
