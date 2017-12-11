import "babel-polyfill"
import {print, test} from "../src/amen"

import basic from "./basic"
import customTimeout from "./custom-timeout"

do ->
  print await test "Using Amen to test itself", [
    test "Basic Tests", basic, false
    test "Custom Timeout", customTimeout, false
  ]
