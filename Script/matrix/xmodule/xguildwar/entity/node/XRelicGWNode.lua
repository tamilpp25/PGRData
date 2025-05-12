local XNormalGWNode = require("XEntity/XGuildWar/Battle/Node/XNormalGWNode")
--- 废墟关卡节点数据
---@class XRelicGWNode: XNormalGWNode
local XRelicGWNode = XClass(XNormalGWNode, 'XRelicGWNode')

-- 获取节点状态：正常，复活中，死亡
-- return : XGuildWarConfig.NodeStatusType
function XRelicGWNode:GetStutesType()
    return XGuildWarConfig.NodeStatusType.Die
end


return XRelicGWNode