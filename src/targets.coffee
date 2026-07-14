import { test } from "./test"
import { isString } from "@dashkite/joy"

getEnvTargets = ->
  envStr = if process? then process.env.targets ? process.env.TARGETS ? process.env.target ? process.env.TARGET
  if ( envStr? ) && ( envStr.trim() != "" )
    envStr.trim().split /\s+/
  else
    []

matchTest = ( node, envTargets ) ->
  (( node.options?.targets? ) && do ->
    testTargets = if Array.isArray node.options.targets then node.options.targets else [ node.options.targets ]
    testTargets.some ( t ) -> t in envTargets
  ) || ( node.description? && do ->
    desc = node.description.toLowerCase()
    envTargets.some ( t ) -> desc.includes t.toLowerCase()
  )

hasMatchingDescendant = ( node, envTargets ) ->
  node.children.some ( child ) ->
    ( matchTest child, envTargets ) || ( hasMatchingDescendant child, envTargets )

shouldRun = ( node ) ->
  envTargets = getEnvTargets()

  if envTargets.length == 0
    if node.options?.targets?
      testTargets = if Array.isArray node.options.targets then node.options.targets else [ node.options.targets ]
      testTargets.length == 0
    else
      true
  else
    ( matchTest node, envTargets ) ||
      (( node.children?.length > 0 ) && ( hasMatchingDescendant node, envTargets ))

target = ( targets, args... ) ->
  envTargets = getEnvTargets()
  targetList = if Array.isArray targets then targets else [ targets ]

  if targetList.some ( t ) -> t in envTargets
    test args...
  else
    description = if isString args[ 0 ] then args[ 0 ] else args[ 0 ]?.description
    test description, undefined

export { shouldRun, target }
