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

getLineage = ( node ) ->
  lineage = []
  current = node
  while current?
    lineage.push current
    current = current.parent
  lineage

getTargetedLineage = ( node ) ->
  ( getLineage node ).filter ( item ) -> item.options?.targets?

matchTags = ( node, active ) ->
  if node.options?.targets?
    ( toArray node.options.targets ).some ( tag ) -> tag in active
  else
    false

matchDescription = ( node, active ) ->
  if node.description?
    description = node.description.toLowerCase()
    active.some ( target ) -> description.includes target.toLowerCase()
  else
    false

matchLineageTags = ( targeted, active ) ->
  ( targeted.length > 0 ) &&
    ( targeted.every ( item ) -> matchTags item, active )

matchUntargetedDescription = ( node, active ) ->
  ( ! node.options?.targets? ) && ( matchDescription node, active )

matchLineage = ( node, active ) ->
  targeted = getTargetedLineage node
  ( matchLineageTags targeted, active ) ||
    ( matchUntargetedDescription node, active )

hasMatchingDescendant = ( node, active ) ->
  ( Boolean node.children?.length ) &&
    ( node.children.some ( child ) ->
      ( matchLineage child, active ) || ( hasMatchingDescendant child, active )
    )

shouldRun = ( node ) ->
  active = getActiveTargets node

  if active.length == 0
    true
  else
    ( matchLineage node, active ) || ( hasMatchingDescendant node, active )

shouldRunHook = ( node, options ) ->
  if ! options?.targets?
    true
  else
    active = getActiveTargets node
    if active.length == 0
      true
    else
      targeted = getTargetedLineage node
      ancestorsMatch =
        ( targeted.length == 0 ) || ( matchLineageTags targeted, active )
      ancestorsMatch && ( matchTags { options }, active )

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

export { shouldRun, shouldRunHook, target }
