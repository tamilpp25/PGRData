---@class XGoldenMinerEntityBuffContainer
local XGoldenMinerEntityBuffContainer = XClass(nil, "XGoldenMinerEntityBuffContainer")

function XGoldenMinerEntityBuffContainer:Ctor()
    ---@type table<number, XGoldenMinerComponentBuff[]> key = BuffId
    self.BuffTypeDir = {}
end

return XGoldenMinerEntityBuffContainer