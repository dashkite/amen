timer = (t) ->
  new Promise (_, nope) ->
    setTimeout (-> nope new Error "Test timed out"), t

race = ( a, b ) -> Promise.race [ a, b ]

timeout = (t, promise ) -> 
  if t?
    race (timer t), [ promise ]
  else
    promise

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

isPromise = ( value ) -> value?.then?

isGenerator = ( value ) ->
  value?[ Symbol.iterator ]?

isAsyncGenerator = ( value ) ->
  value?[ Symbol.asyncIterator ]?

target = ( targets, args... ) ->
  if targets.find ( target ) -> target in $targets
    test args...

run = ( definition, { wait }) ->
  result = definition()
  if isPromise result
    timeout wait, result
  else if isGenerator result
    undefined for value from result
    # avoid accumulation
    undefined
  else if isAsyncGenerator result
    timeout wait, do -> 
      undefined for await value from result
      return
  else
    result

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
        [ description, ( await Promise.all definition )]
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
