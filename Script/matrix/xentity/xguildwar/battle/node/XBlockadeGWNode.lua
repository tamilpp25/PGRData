local XNormalGWNode = require("XEntity/XGuildWar/Battle/Node/XNormalGWNode")

---@class XBlockadeGWNode:XGWNode@封锁点
local XBlockadeGWNode = XClass(XNormalGWNode, "XBlockadeGWNode")

function XBlockadeGWNode:Ctor(id)
end

function XBlockadeGWNode:UpdateWithServerData(data, ...)
    XBlockadeGWNode.Super.UpdateWithServerData(self, data, ...)
end

function XBlockadeGWNode:GetBlockEffectName()
    return "Todo"
end

return XBlockadeGWNode
