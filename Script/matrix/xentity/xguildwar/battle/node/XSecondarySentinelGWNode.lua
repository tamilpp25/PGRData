local XGWEliteMonster = require("XEntity/XGuildWar/Battle/XGWEliteMonster")
local XNormalGWNode = require("XEntity/XGuildWar/Battle/Node/XNormalGWNode")
-- 前哨区节点
local XSecondarySentinelGWNode = XClass(XNormalGWNode, "XSecondarySentinelGWNode")

function XSecondarySentinelGWNode:Ctor(id)
    -- 节点死亡时间
    self.DeadTime = 0
    -- 节点增加的重建时间
    self.AddRebuildTime = 0
    -- 出生的精英怪 XGWEliteMonster
    self.BornMonster = nil
    -- 下一个精英怪出生的时间
    self.NextMonsterBornTime = nil
end

-- data : XGuildWarNodeData
function XSecondarySentinelGWNode:UpdateWithServerData(data)
    XSecondarySentinelGWNode.Super.UpdateWithServerData(self, data)
    self.DeadTime = data.DeadTime or 0
    self.AddRebuildTime = data.AddRebuildTime or 0
    self.NextMonsterBornTime = data.NextMstBornTime or 0
end

function XSecondarySentinelGWNode:GetNextMonsterBornTimeTip()
    return XUiHelper.GetTime(math.max(0, self.NextMonsterBornTime 
        - XTime.GetServerNowTimestamp()), XUiHelper.TimeFormatType.HOUR_MINUTE_SECOND)
end

-- 获取重建时间
function XSecondarySentinelGWNode:GetRebuildTime(addRebuildTime)
    if addRebuildTime == nil then addRebuildTime = 0 end
    addRebuildTime = self.AddRebuildTime + addRebuildTime
    return math.min(self.DeadTime + self.Config.RebuildTime + addRebuildTime
        , self.DeadTime + self.Config.RebuildMaxTime)
end

function XSecondarySentinelGWNode:GetRebuildTimeStr(addRebuildTime)
    local nowTime = XTime.GetServerNowTimestamp()
    return XUiHelper.GetTime(math.max(0, self:GetRebuildTime(addRebuildTime) 
        - nowTime), XUiHelper.TimeFormatType.HOUR_MINUTE_SECOND)
end

function XSecondarySentinelGWNode:GetIsOverMaxRebuildTime()
    return self.Config.RebuildTime + self.AddRebuildTime
        > self.Config.RebuildMaxTime
end

function XSecondarySentinelGWNode:GetMaxRebuildMaxTime()
    return self.DeadTime + self.Config.RebuildMaxTime
end

function XSecondarySentinelGWNode:GetOverRebuildTime()
    return self.Config.RebuildTime + self.AddRebuildTime - self.Config.RebuildMaxTime
end

-- 获取历史最高重建时间
function XSecondarySentinelGWNode:GetHistoryMaxRebuildTime()
    local damage = XDataCenter.GuildWarManager
        .GetBattleManager():GetMaxDamageByUID(self:GetUID(), XGuildWarConfig.FightRecordAliveType.Die)
    return self:GetRebuildTimeByDamage(damage)
end

-- 根据伤害获取重建时间
function XSecondarySentinelGWNode:GetRebuildTimeByDamage(value)
    return value / self.Config.MaxSubHp * self.Config.RebuildTimeFactor 
end

-- 获取重建进度
function XSecondarySentinelGWNode:GetRebuildProgress(addRebuildTime)
    return (XTime.GetServerNowTimestamp() - self.DeadTime) / (self:GetRebuildTime(addRebuildTime) - self.DeadTime)
end

-- 获取节点状态：正常，复活中，死亡
-- return : XGuildWarConfig.NodeStatusType
function XSecondarySentinelGWNode:GetStutesType()
    local result = XSecondarySentinelGWNode.Super.GetStutesType(self)
    return result
end

function XSecondarySentinelGWNode:GetBornMonster()
    if self.BornMonster == nil then
        self.BornMonster = XGWEliteMonster.New(self.Config.EliteMonsterId)
    end
    return self.BornMonster
end

function XSecondarySentinelGWNode:GetStageId()
    return XSecondarySentinelGWNode.Super.GetStageId(self)
end

-- 检查是否能够扫荡
function XSecondarySentinelGWNode:CheckCanSweep(checkCostEnergy)
    if self:GetMaxDamage() <= 0 then
        return false
    end
    if checkCostEnergy then
        return XDataCenter.GuildWarManager.GetCurrentActionPoint() >= self.Config.SweepCostEnergy
    end
    return true
end

-- 获取当前节点当场最高伤害
function XSecondarySentinelGWNode:GetMaxDamage()
    local aliveType = XGuildWarConfig.FightRecordAliveType.Die
    if self:GetHP() > 0 then
        aliveType = XGuildWarConfig.FightRecordAliveType.Alive
    end
    return XDataCenter.GuildWarManager
        .GetBattleManager():GetMaxDamageByUID(self.UID, aliveType)
end

-- 检查是否能够扫荡
function XSecondarySentinelGWNode:CheckCanSweep(checkCostEnergy)
    if self:GetMaxDamage() <= 0 then
        return false
    end
    if checkCostEnergy then
        return XDataCenter.GuildWarManager.GetCurrentActionPoint() >= self.Config.SweepCostEnergy
    end
    return true
end

function XSecondarySentinelGWNode:GetEliteMonsterBornInterval()
    return self.Config.EliteMonsterBornInterval
end

return XSecondarySentinelGWNode