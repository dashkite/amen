getIndent = ( test ) ->
  indent = ""
  parent = test.parent
  while parent?
    indent += "  "
    parent = parent.parent
  indent

print = ( target, indent = "" ) ->
  if target?[ Symbol.asyncIterator ]?
    for await event from target
      indentation = getIndent event.test
      switch event.type
        when 'group:start'
          console.error indentation, event.test.description
        when 'test:success'
          console.error indentation, "pass - #{event.test.description}"
        when 'test:failure'
          msg = if event.error?.message? then " (#{event.error.message})" else ""
          console.error indentation, "fail - #{event.test.description}#{msg}"
        when 'test:skipped', 'test:pending'
          console.error indentation, "pending - #{event.test.description}"
  else if Array.isArray target
    [ description, result ] = target
    if Array.isArray result
      console.error indent, description
      for child in result
        print child, ( indent + "  " )
    else
      console.error indent,
        if result?
          if result == true
            "pass - #{description}"
          else if ( result.message? ) && ( result.message != "" )
            "fail - #{description} (#{result.message})"
          else
            "fail - #{description}"
        else
          "pending - #{description}"

export { print }
export default print
