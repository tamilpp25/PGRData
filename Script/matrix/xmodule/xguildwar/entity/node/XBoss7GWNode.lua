local XTerm4BossGWNode = require("XEntity/XGuildWar/Battle/Node/XTerm4BossGWNode")

--- 七期的Boss节点数据
---@class XBoss7GWNode: XTerm4BossGWNode
local XBoss7GWNode = XClass(XTerm4BossGWNode, 'XBoss7GWNode')

function XBoss7GWNode:GetAllGuardIsDead()
    return XDataCenter.GuildWarManager:GetBattleManager():GetAllGuardIsDead()
end

function XBoss7GWNode:GetShowMonsterName()
    return XTerm4BossGWNode.Super.GetShowMonsterName(self)
end

--地图界面移动到这个节点时回调
function XBoss7GWNode:OnDetailGoCallback()
    if not self:GetIsDead() then
        XLuaUiManager.Close("UiGuildWarStageDetail")
        XLuaUiManager.Open("UiGuildWarBoss7Panel", self)
        return true
    end
    return false
end

-- 检查是否能够扫荡
function XBoss7GWNode:CheckCanSweep(checkCostEnergy)
    if self:GetIsDead() then
        return false
    end
    if self:GetMaxDamage() <= 0 then
        return false
    end
    if checkCostEnergy then
        return XDataCenter.GuildWarManager.GetCurrentActionPoint() >= self.Config.SweepCostEnergy
    end
    return true
end

-- 获取当前节点当场最高伤害
function XBoss7GWNode:GetMaxDamage()
    local aliveType = XGuildWarConfig.FightRecordAliveType.Die
    if self:GetHP() > 0 then
        aliveType = XGuildWarConfig.FightRecordAliveType.Alive
    end
    return XDataCenter.GuildWarManager.GetBattleManager():GetMaxDamageByUID(self.UID, aliveType)
end

return XBoss7GWNode