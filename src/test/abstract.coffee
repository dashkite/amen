import { once, isFunction } from "@dashkite/joy"
import { shouldRunHook } from "../targets"

parseHook = ( args ) ->
  if isFunction args[ 0 ]
    options: {}
    callback: args[ 0 ]
  else
    [ options, callback ] = args
    { options: ( options ? {} ), callback }

class AbstractTest
  constructor: ->
    @status = "pending"
    @run = once @run
    @promise = new Promise ( resolve, reject ) =>
      @_resolve = resolve
      @_reject = reject
    @_ready = new Promise ( resolve ) =>
      @_markReady = resolve
    @_before = []
    @_after = []

  before: ( args... ) ->
    @_before.push parseHook args
    @

  after: ( args... ) ->
    @_after.push parseHook args
    @

  run: ->
    if @status == "skipped"
      @_markReady()
      @_resolve @
      @promise
    else
      @status = "running"
      ready = false
      try
        for { options, callback } in @_before
          if shouldRunHook @, options
            await callback.call @

        ready = true
        @_markReady()
        await @apply()

        if @status == "running"
          @_pass()
        else
          @_resolve @
      catch error
        unless ready
          @_beforeError = error
          @_hookError = error
          @_markReady()
        @_fail error
      finally
        for { options, callback } in @_after
          if shouldRunHook @, options
            try
              await callback.call @
            catch hookError
              @_afterError = hookError
              @_hookError ?= hookError
              @_fail hookError





  [ Symbol.asyncIterator ]: ->
    iterator = @_iterate()
    iterator.test = @
    iterator

  _fail: ( error ) ->
    @status = "failed"
    @error = error
    @_resolve @
    @promise

  _pass: ->
    @status = "passed"
    @_resolve @
    @promise

  _skip: ->
    @status = "skipped"
    @_resolve @
    @promise

  count: ->
    if @description?
      1
    else
      0

  _iterate: ->
    if @description?
      runPromise = @run()
      yield type: "test:start", test: @
      await runPromise
      switch @status
        when "passed"
          yield type: "test:success", test: @
        when "failed"
          yield type: "test:failure", test: @, error: @error
        when "skipped"
          yield type: "test:skipped", test: @
        else
          yield type: "test:pending", test: @
    else
      yield from []

export { AbstractTest }
export default AbstractTest
