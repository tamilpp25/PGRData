local XTemple2Enum = require("XModule/XTemple2/XTemple2Enum")

---@class XTemple2Interact
local XTemple2Interact = XClass(nil, "XTemple2Interact")

function XTemple2Interact:Ctor()
    self._Id = 0
    self._Type = 0
    self._Params = {}
end

function XTemple2Interact:SendEvent(event, ...)
    if event == XTemple2Enum.EVENT.PASS_GRID then
        local params = { ... }
        local gridId = params[1]
    end
end

return XTemple2Interact