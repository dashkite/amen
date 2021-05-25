import chalk from "chalk"

timer = (t) ->
  new Promise (_, nope) ->
    setTimeout (-> nope new Error "Test timed out"), t

race = (promises...) -> Promise.race [promises...]

timeout = (t, promises...) -> race (timer t), promises...

defaults = wait: 1000

success = true

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
      [ description, (await Promise.all definition) ]
    else if definition.call?
      try
        result = definition()
        if wait == false then await result else await timeout wait, result
        [ description, true ]
      catch error
        success = false # at least one failing test
        if error.message != "Test timed out"
          console.error chalk.red "#{error.stack}"
        [ description, error ]
    else
      [ description, (new Error "Invalid test definition") ]
  else
    [ description, undefined ]

# TODO: add error counts for groups
# TODO: groups with failing/pending tests should be red
print = ([description, result], indent="") ->
  if Array.isArray result
    console.error indent, chalk.blue description
    for r in result
      print r, (indent + "  ")
  else
    console.error indent,
      if result?
        if result == true
          chalk.green description
        else if result.message? and result.message != ""
          chalk.red "#{description} (#{result.message})"
        else
          chalk.red description
      else
        chalk.yellow description

export { test, print, success }
