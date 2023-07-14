local XNormalGWNode = require("XEntity/XGuildWar/Battle/Node/XNormalGWNode")
-- Buff节点
local XBuffGWNode = XClass(XNormalGWNode, "XBuffGWNode")

function XBuffGWNode:Ctor(id)
end

function XBuffGWNode:GetShowFightEventId()
    return XGuildWarConfig.GetBuffFightEventId(self.Config.BuffGroupId
        , (self:GetHP() / self:GetMaxHP()) * 100)
end

-- StageFightEventDetails 配置表
function XBuffGWNode:GetFightEventDetailConfig()
    local fightEventId = self:GetShowFightEventId()
    if fightEventId <= 0 then
        return nil
    end
    return XFubenConfigs.GetStageFightEventDetailsByStageFightEventId(fightEventId)
end

function XBuffGWNode:GetShowFightEventDetailConfig()
    if self:GetIsActiveBuff() then
        return self:GetFightEventDetailConfig()
    end
    return XFubenConfigs.GetStageFightEventDetailsByStageFightEventId(self.Config.ShowFightEventId)
end

function XBuffGWNode:GetIsActiveBuff()
    return self:GetShowFightEventId() > 0
end

function XBuffGWNode:GetBuffName()
    return self:GetFightEventDetailConfig().Name
end

function XBuffGWNode:GetBuffIcon()
    return self:GetFightEventDetailConfig().Icon
end

function XBuffGWNode:GetBuffDesc()
    return self:GetFightEventDetailConfig().Description
end

return XBuffGWNode
