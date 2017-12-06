require "colors"

timeout = (t, promise) ->
  timer = new Promise (_, reject) ->
    setTimeout (-> reject new Error "Async test timed out"), t
  Promise.race [ timer, promise ]

# TODO: use explicit result objects, instead of true | Error | undefined
test = (description, definition) ->
  if definition?
    if Array.isArray definition
      # TODO: include error/timeout/pending count in result object
      [description, (await result for result in definition) ]
    else if definition.call?
      try
        await timeout 1000, definition()
        [ description, true ]
      catch error
        [ description, error ]
    else
      [ description, (new Error "Invalid test definition") ]
  else
    [ description, undefined ]

# TODO: add error counts for groups
# TODO: groups with failing/pending tests should be red
print = ([description, result], indent="") ->
  if Array.isArray result
    console.log indent, description.blue
    for test in result
      print test, (indent + "  ")
  else
    console.log indent,
      if result?
        if result == true
          description.green
        else if result.message? and result.message != ""
          "#{description.red} (#{result.message?.red})"
        else
          description.red
      else
        description.yellow

export {test, print}
