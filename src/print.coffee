printTree = ( test, indent = "" ) ->
  if test.description?
    if test.children?
      console.error indent + test.description
      for child in test.children
        printTree child, ( indent + "  " )
    else
      status = test.status
      if status == "passed"
        console.error indent + "pass - #{test.description}"
      else if status == "failed"
        if process?
          process.exitCode = 1
        msg = if test.error?.message? then " (#{test.error.message})" else ""
        console.error indent + "fail - #{test.description}#{msg}"
      else if status == "skipped"
        console.error indent + "skipped - #{test.description}"
      else
        console.error indent + "pending - #{test.description}"
  else
    if test.children?
      for child in test.children
        printTree child, indent

print = ( target, indent = "" ) ->
  if target?[ Symbol.asyncIterator ]?
    for await event from target
      undefined
    printTree target, indent
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
          else
            if process?
              process.exitCode = 1
            msg = if result.message? && result.message != "" then " (#{result.message})" else ""
            "fail - #{description}#{msg}"
        else
          "pending - #{description}"

export { print }
export default print
