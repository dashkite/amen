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

matchTags = ( node, active ) ->
  if node.options?.targets?
    ( toArray node.options.targets ).some ( tag ) -> tag in active
  else
    false

matchDescription = ( node, active ) ->
  if node.description?
    desc = node.description.toLowerCase()
    active.some ( target ) -> desc.includes target.toLowerCase()
  else
    false

matchTest = ( node, active ) ->
  ( matchTags node, active ) || ( matchDescription node, active )

hasMatchingDescendant = ( node, active ) ->
  node.children.some ( child ) ->
    ( matchTest child, active ) || ( hasMatchingDescendant child, active )

hasMatchingAncestor = ( node, active ) ->
  current = node.parent
  while current?
    if matchTags current, active
      return true
    current = current.parent
  false

shouldRun = ( node ) ->
  active = getActiveTargets node

  if active.length == 0
    true
  else
    ( matchTest node, active ) ||
      ( hasMatchingAncestor node, active ) ||
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
