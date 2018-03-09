require "colors"

timer = (t) ->
  new Promise (_, nope) ->
    setTimeout (-> nope new Error "Test timed out"), t

race = (promises...) -> Promise.race [promises...]

timeout = (t, promises...) -> race (timer t), promises...

defaults =
  wait: 500

# TODO: use explicit result objects, instead of true | Error | undefined
test = (description, definition) ->
  if description.constructor == Object
    {description, wait} = description
  else if description.constructor == String
    {wait} = defaults
  else
    description = description.toString()


  if definition?
    if Array.isArray definition
      # TODO: include error/timeout/pending count in result object
      [description, (await result for result in definition) ]
    else if definition.call?
      try
        if wait == false
          await definition()
        else
          await timeout wait, definition()
        [ description, true ]
      catch error
        console.error "#{error.stack.red}" if error.message != "Test timed out"
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
    for r in result
      print r, (indent + "  ")
  else
    console.log indent,
      if result?
        if result == true
          description.green
        else if result.message? and result.message != ""
          "#{description.red} (#{result.message.red})"
        else
          description.red
      else
        description.yellow

export {test, print}
