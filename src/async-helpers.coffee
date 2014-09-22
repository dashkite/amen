{promise} = require "when"
{lift, call} = require "when/generator"
module.exports = {promise, async: lift, call}
