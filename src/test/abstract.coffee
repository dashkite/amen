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

export { AbstractTest }
export default AbstractTest
