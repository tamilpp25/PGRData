local XNormalGWNode = require("XEntity/XGuildWar/Battle/Node/XNormalGWNode")
-- 黑白鲨节点
---@class XTwinsChildGWNode:XGWNode
local XTwinsChildGWNode = XClass(XNormalGWNode, "XTwinsChildGWNode")

function XTwinsChildGWNode:Ctor(id)
    self.NextBossAttackTime = false
    self.Weakness = false
end
-- data : XGuildWarNodeData
function XTwinsChildGWNode:UpdateWithServerData(data, ...)
    XTwinsChildGWNode.Super.UpdateWithServerData(self, data, ...)
    if data == nil then data = {} end
    self.NextBossAttackTime = data.NextBossAttackTime
    self.Weakness = data.Weakness
end
-- 更新进攻时间
function XTwinsChildGWNode:UpdateNextBossAttackTime(time)
    if time then
        self.NextBossAttackTime = time
    end
end

-- 获取名字
function XTwinsChildGWNode:GetName(checkDead)
    if checkDead == nil then checkDead = true end
    if checkDead and self:GetIsDead() then
        return XUiHelper.GetText("GuildWarResidueName")
    else
        return self.Config.Name
    end
end
-- 获取英文名
function XTwinsChildGWNode:GetNameEn()
    if self:GetIsDead() then
        return XUiHelper.GetText("GuildWarResidueNameEn")
    else
        return self.Config.NameEn
    end
end
-- 获取当前节点当场最高伤害
function XTwinsChildGWNode:GetMaxDamage()
    local aliveType = XGuildWarConfig.FightRecordAliveType.Die
    if self:GetHP() > 0 then
        aliveType = XGuildWarConfig.FightRecordAliveType.Alive
    end
    return XDataCenter.GuildWarManager.GetBattleManager():GetMaxDamageByUID(self.UID, aliveType)
end
-- 获取节点血量
function XTwinsChildGWNode:GetHP()
    return self.HP
end
-- 获取显示模型
function XTwinsChildGWNode:GetModelId(pandaType)
    return XGuildWarConfig.GetChildNodeModelId(self:GetId(), pandaType)
end
-- 获取离BOSS节点攻击剩余时间
function XTwinsChildGWNode:GetTimeToBossAttack()
    if self:GetIsDead() then
        return 0
    end
    return (self.NextBossAttackTime or 0) - XTime.GetServerNowTimestamp()
end
-- 获取关卡ID
function XTwinsChildGWNode:GetStageId()
    return XTwinsChildGWNode.Super.GetStageId(self)
end
-- 检查是否能够扫荡
function XTwinsChildGWNode:CheckCanSweep(checkCostActionPoint)
    if self:GetMaxDamage() <= 0 then
        return false
    end
    if checkCostActionPoint then
        return XDataCenter.GuildWarManager.GetCurrentActionPoint() >= self.Config.SweepCostEnergy
    end
    return true
end
--残留区
function XTwinsChildGWNode:GetIsRuinsStatus()
    return self:GetIsDead()
end
-- 获取展示怪物名字
function XTwinsChildGWNode:GetShowMonsterName()
    return XTwinsChildGWNode.Super.GetShowMonsterName(self)
end

-- 虚弱状态(暴露弱点)
function XTwinsChildGWNode:HasWeakness()
    return self.Weakness == 1
end
function XTwinsChildGWNode:SetWeakness(value)
    self.Weakness = value and 1 or 0
end

return XTwinsChildGWNode
