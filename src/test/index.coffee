import Generic from "@dashkite/generic"
import {
  isString
  isObject
  isFunction
  isIterable
  isThenable
} from "@dashkite/joy"

import { AbstractTest } from "./abstract"
import { TestGroup } from "./group"
import { RunnableTest } from "./runnable"
import { PendingTest } from "./pending"
import { ComputedTest } from "./computed"

defaults = wait: undefined

isAny = -> true

test = Generic.make
  name: "test"
  default: ( args... ) ->
    throw new Error "test: unsupported argument signature"

# 1. Single-argument definitions (checked last)
test.define [ String ], ( description ) ->
  PendingTest.make description, defaults

test.define [ isObject ], ({ description, options... }) ->
  PendingTest.make description, { defaults..., options... }

# 2. 2-argument definitions with options as first argument
test.define [ isObject, isAny ], ({ description, options... }, definition ) ->
  ComputedTest.make description, definition, { defaults..., options... }

test.define [ isObject, isIterable ], ({ description, options... }, definition ) ->
  TestGroup.make description, definition, { defaults..., options... }

test.define [ isObject, isFunction ], ({ description, options... }, definition ) ->
  RunnableTest.make description, definition, { defaults..., options... }

# 3. 2-argument definitions with description as first argument
test.define [ String, isAny ], ( description, definition ) ->
  ComputedTest.make description, definition, defaults

test.define [ String, isIterable ], ( description, definition ) ->
  TestGroup.make description, definition, defaults

test.define [ String, isFunction ], ( description, definition ) ->
  RunnableTest.make description, definition, defaults

test.define [ String, isObject ], ( description, options ) ->
  PendingTest.make description, { defaults..., options... }

# 4. 3-argument definitions
test.define [ String, isObject, isAny ], ( description, options, definition ) ->
  ComputedTest.make description, definition, { defaults..., options... }

test.define [ String, isObject, isIterable ], ( description, options, definition ) ->
  TestGroup.make description, definition, { defaults..., options... }

test.define [ String, isObject, isFunction ], ( description, options, definition ) ->
  RunnableTest.make description, definition, { defaults..., options... }

export {
  AbstractTest
  TestGroup
  RunnableTest
  PendingTest
  ComputedTest
  test
}
