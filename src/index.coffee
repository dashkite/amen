timer = (t) ->
  new Promise (_, nope) ->
    setTimeout (-> nope new Error "Test timed out"), t

race = (promises...) -> Promise.race [promises...]

timeout = (t, promises...) -> race (timer t), promises...

defaults = wait: undefined

success = true

makeError = (error) ->
  success: false
  message: error.message
  stack: error.stack

merge = ( a, b ) -> { a..., b... }

$targets = ( process?.env[ "targets" ]?.split /\s/ ) ? []

isString = ( value ) -> value?.constructor == String
isObject = ( value ) -> value?.constructor == Object
isAsyncFunction = do ({ T } = {}) ->
  T = ( -> await null ).constructor
  ( f ) -> f instanceof T
isGeneratorFunction = do ({ T } = {}) ->
  T = ( -> yield null ).constructor
  ( f ) -> f instanceof T
isAsyncGeneratorFunction = do ({ T } = {}) ->
  T = ( -> yield await null ).constructor
  ( f ) -> f instanceof T

target = ( targets, args... ) ->
  if targets.find ( target ) -> target in $targets
    test args...

runAsyncTest = ( definition, wait ) ->
  if wait?
    timeout wait, definition()
  else definition()

runGeneratorTest = ( definition ) ->
  undefined for x from definition() ; return

runAsyncGeneratorTest = ( definition, wait ) ->
  if wait?
    timeout wait, do ->
      undefined for await x from definition() ; return
  else
    undefined for await x from definition() ; return

run = ( definition, { wait }) ->
  if isAsyncFunction definition
    runAsyncTest definition, wait
  else if isGeneratorFunction definition
    runGeneratorTest definition
  else if isAsyncGeneratorFunction definition
    runAsyncGeneratorTest definition, wait
  else if wait?
    timeout wait, definition()
  else
    definition()

test = ( args... ) ->
  do ({ description, wait, definition, options } = {}) ->
    if isString args[0]
      if isObject args[1]
        [ description, options, definition ] = args
      else
        [ description, definition ] = args
    else if isObject args[0]
      [ options, definition ] = args
      { description } = options

    { wait, targets } = merge defaults, options
      
    if definition?
      if Array.isArray definition
        [ description, ( await Promise.all definition ) ]
      else if definition.call?
        try
          await run definition, { wait }
          [ description, true ]          
        catch error
          success = false # at least one failing test
          [ description, makeError error ]
      else
        [ description, makeError new Error "Invalid test definition" ]
    else
      [ description, undefined ]


print = ([description, result], indent="") ->
  if Array.isArray result
    console.error indent, description
    for r in result
      print r, (indent + "  ")
  else
    console.error indent,
      if result?
        if result == true
          "pass - #{description}"
        else if result.message? and result.message != ""
          "fail - #{description} (#{result.message})"
        else
          "fail - #{description}"
      else
        "pending - description"

export { test, print, success }
