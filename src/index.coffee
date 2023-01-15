timer = (t) ->
  new Promise (_, nope) ->
    setTimeout (-> nope new Error "Test timed out"), t

race = (promises...) -> Promise.race [promises...]

timeout = (t, promises...) -> race (timer t), promises...

defaults = wait: false

success = true

makeError = (error) ->
  success: false
  message: error.message
  stack: error.stack

merge = ( a, b ) -> { a..., b... }

$targets = ( process.env[ "targets" ]?.split /\s/ ) ? []

# TODO: use explicit result objects, instead of true | Error | undefined

isString = ( value ) -> value?.constructor == String
isObject = ( value ) -> value?.constructor == Object

target = ( targets, args... ) ->
  if targets.find ( target ) -> target in $targets
    test args...

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
        # TODO: include error/timeout/pending count in result object
        [ description, ( await Promise.all definition ) ]
      else if definition.call?
        try
          result = definition()
          if wait == false then await result else await timeout wait, result
          [ description, true ]
        catch error
          success = false # at least one failing test
          [ description, makeError error ]
      else
        [ description, makeError new Error "Invalid test definition" ]
    else
      [ description, undefined ]

# TODO: add error counts for groups
# TODO: groups with failing/pending tests should be red

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
