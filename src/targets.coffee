import { test } from "./test"
import { isString, isObject } from "@dashkite/joy"

getActiveTargets = ( node ) ->
  current = node
  while current?
    active = current.options?.active ? current.active
    if active?
      return if Array.isArray active then active else [ active ]
    current = current.parent
  []

matchTest = ( node, active ) ->
  (( node.options?.targets? ) && do ->
    testTargets = if Array.isArray node.options.targets then node.options.targets else [ node.options.targets ]
    testTargets.some ( t ) -> t in active
  ) || ( node.description? && do ->
    desc = node.description.toLowerCase()
    active.some ( t ) -> desc.includes t.toLowerCase()
  )

hasMatchingDescendant = ( node, active ) ->
  node.children.some ( child ) ->
    ( matchTest child, active ) || ( hasMatchingDescendant child, active )

shouldRun = ( node ) ->
  active = getActiveTargets node

  if active.length == 0
    true
  else
    ( matchTest node, active ) ||
      (( node.children?.length > 0 ) && ( hasMatchingDescendant node, active ))

target = ( targets, args... ) ->
  if isString args[ 0 ]
    if isObject args[ 1 ]
      [ description, options, definition ] = args
      test description, { targets, options... }, definition
    else
      [ description, definition ] = args
      test description, { targets }, definition
  else if isObject args[ 0 ]
    [ options, definition ] = args
    test { targets, options... }, definition
  else
    test args...

export { shouldRun, target }
