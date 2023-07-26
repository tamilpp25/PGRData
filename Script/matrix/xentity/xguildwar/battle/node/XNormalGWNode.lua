local XGWNode = require("XEntity/XGuildWar/Battle/Node/XGWNode")
-- 普通区节点
local XNormalGWNode = XClass(XGWNode, "XNormalGWNode")

function XNormalGWNode:Ctor(id)
end

-- data : XGuildWarNodeData
function XNormalGWNode:UpdateWithServerData(data)
    XNormalGWNode.Super.UpdateWithServerData(self, data)
end

-- 获取节点当前精英怪
-- return : { XGWEliteMonster }
function XNormalGWNode:GetEliteMonsters(checkIsDead)
    return XDataCenter.GuildWarManager
        .GetBattleManager():GetMonstersByNodeId(self:GetId(), checkIsDead)
end

function XNormalGWNode:GetCurrentEliteMonster(checkIsDead)
    local monsters = self:GetEliteMonsters(checkIsDead)
    table.sort(monsters, function(aMonster, bMonster)
        return aMonster:GetUID() > bMonster:GetUID()
    end)
    return monsters[1]
end

-- 获取节点当前是否在战斗中
function XNormalGWNode:GetIsInBattle()
    if self:GetMemberCount() > 0 then
        if next(self:GetEliteMonsters()) or (self:GetStutesType() == XGuildWarConfig.NodeStatusType.Alive) then
            return true
        else
            return false
        end
    else
        return false
    end
end

function XNormalGWNode:GetIsCanBattle()
    return true
end

-- 获取展示节点怪物的图标
function XNormalGWNode:GetShowMonsterIcon()
    return self.Config.ShowMonsterIcon
end

-- 获取展示节点怪物的名称
function XNormalGWNode:GetShowMonsterName()
    return self.Config.ShowMonsterName
end

-- 获取当前节点当场最高伤害
function XNormalGWNode:GetMaxDamage()
    local aliveType = XGuildWarConfig.FightRecordAliveType.Alive
    return XDataCenter.GuildWarManager
        .GetBattleManager():GetMaxDamageByUID(self.UID, aliveType)
end

-- 检查是否能够战斗
function XNormalGWNode:CheckCanFight()
    local currentEnergy = XDataCenter.GuildWarManager.GetCurrentActionPoint()
    return currentEnergy >= self.Config.FightCostEnergy
end

-- 检查是否能够扫荡
function XNormalGWNode:CheckCanSweep(checkCostEnergy)
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

function XNormalGWNode:GetFightCostEnergy()
    return self.Config.FightCostEnergy
end

function XNormalGWNode:GetSweepCostEnergy()
    return self.Config.SweepCostEnergy
end

function XNormalGWNode:GetStageId()
    if self.Config.GuildWarStageId == 0 then
        return 0
    end
    return XGuildWarConfig.GetCfgByIdKey(XGuildWarConfig.TableKey.Stage
        , self.Config.GuildWarStageId).StageId
end

return XNormalGWNode