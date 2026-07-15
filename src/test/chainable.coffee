import { AbstractTest } from "./abstract"
import { TestChain } from "./chain"

chainable = ( base = Object ) ->
  class extends base
    and: ( resolve ) ->
      if resolve instanceof AbstractTest
        new TestChain @, resolve
      else
        throw new Error "and: argument must be an instance of AbstractTest"

export { chainable }
export default chainable
