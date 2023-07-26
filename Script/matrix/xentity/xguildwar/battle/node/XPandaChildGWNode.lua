local XNormalGWNode = require("XEntity/XGuildWar/Battle/Node/XNormalGWNode")
-- 黑白鲨节点
---@class XPandaChildGWNode:XGWNode
local XPandaChildGWNode = XClass(XNormalGWNode, "XPandaChildGWNode")

function XPandaChildGWNode:Ctor(id)
    self.NextBossAttackTime = false
    self.Weakness = false
end
-- data : XGuildWarNodeData
function XPandaChildGWNode:UpdateWithServerData(data, ...)
    XPandaChildGWNode.Super.UpdateWithServerData(self, data, ...)
    if data == nil then data = {} end
    self.NextBossAttackTime = data.NextBossAttackTime
    self.Weakness = data.Weakness
end
-- 更新进攻时间
function XPandaChildGWNode:UpdateNextBossAttackTime(time)
    if time then
        self.NextBossAttackTime = time
    end
end

-- 获取名字
function XPandaChildGWNode:GetName(checkDead)
    if checkDead == nil then checkDead = true end
    if checkDead and self:GetIsDead() then
        return XUiHelper.GetText("GuildWarResidueName")
    else
        return self.Config.Name
    end
end
-- 获取英文名
function XPandaChildGWNode:GetNameEn()
    if self:GetIsDead() then
        return XUiHelper.GetText("GuildWarResidueNameEn")
    else
        return self.Config.NameEn
    end
end
-- 获取当前节点当场最高伤害
function XPandaChildGWNode:GetMaxDamage()
    local aliveType = XGuildWarConfig.FightRecordAliveType.Die
    if self:GetHP() > 0 then
        aliveType = XGuildWarConfig.FightRecordAliveType.Alive
    end
    return XDataCenter.GuildWarManager.GetBattleManager():GetMaxDamageByUID(self.UID, aliveType)
end
-- 获取节点血量
function XPandaChildGWNode:GetHP()
    return self.HP
end
-- 获取显示模型
function XPandaChildGWNode:GetModelId(pandaType)
    return XGuildWarConfig.GetChildNodeModelId(self:GetId(), pandaType)
end
-- 获取离BOSS节点攻击剩余时间
function XPandaChildGWNode:GetTimeToBossAttack()
    if self:GetIsDead() then
        return 0
    end
    return (self.NextBossAttackTime or 0) - XTime.GetServerNowTimestamp()
end
-- 获取关卡ID
function XPandaChildGWNode:GetStageId()
    return XPandaChildGWNode.Super.GetStageId(self)
end
-- 检查是否能够扫荡
function XPandaChildGWNode:CheckCanSweep(checkCostActionPoint)
    if self:GetMaxDamage() <= 0 then
        return false
    end
    if checkCostActionPoint then
        return XDataCenter.GuildWarManager.GetCurrentActionPoint() >= self.Config.SweepCostEnergy
    end
    return true
end
--残留区
function XPandaChildGWNode:GetIsRuinsStatus()
    return self:GetIsDead()
end
-- 获取展示怪物名字
function XPandaChildGWNode:GetShowMonsterName()
    return XPandaChildGWNode.Super.GetShowMonsterName(self)
end

-- 虚弱状态(暴露弱点)
function XPandaChildGWNode:HasWeakness()
    return self.Weakness == 1
end
function XPandaChildGWNode:SetWeakness(value)
    self.Weakness = value and 1 or 0
end

return XPandaChildGWNode
