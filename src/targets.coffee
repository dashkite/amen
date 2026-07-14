import { test } from "./test"
import { isString, isObject } from "@dashkite/joy"

toArray = ( value ) ->
  if Array.isArray value
    value
  else
    [ value ]

getActiveTargets = ( node ) ->
  current = node
  result = undefined
  while ( current? ) && ( ! result? )
    active = current.options?.active ? current.active
    if active?
      result = toArray active
    current = current.parent
  result ? []

matchTest = ( node, active ) ->
  (( node.options?.targets? ) && do ->
    ( toArray node.options.targets ).some ( t ) -> t in active
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
