local slotover = require("slotover")

local ok, userConfig = pcall(require, "config")
if not ok then
  userConfig = {}
end

slotover.start(userConfig)
