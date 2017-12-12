import "babel-polyfill"
import {print, test} from "../src/amen"

import basic from "./basic"
import customTimeout from "./custom-timeout"

do ->
  print await test "Using Amen to test itself", [
    test
      description: "Basic Tests"
      wait: false,
      basic

    test
      description: "Custom Timeout"
      wait: false,
      customTimeout
  ]
