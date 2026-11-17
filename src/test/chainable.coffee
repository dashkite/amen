import { TestChain } from "./chain"

chainable = ( base = Object ) ->
  class extends base
    and: ( resolve ) ->
      new TestChain @, resolve

export { chainable }
export default chainable
