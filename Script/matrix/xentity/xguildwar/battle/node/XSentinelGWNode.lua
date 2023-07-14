local XGWEliteMonster = require("XEntity/XGuildWar/Battle/XGWEliteMonster")
local XNormalGWNode = require("XEntity/XGuildWar/Battle/Node/XNormalGWNode")
-- 前哨区节点
local XSentinelGWNode = XClass(XNormalGWNode, "XSentinelGWNode")

function XSentinelGWNode:Ctor(id)
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
function XSentinelGWNode:UpdateWithServerData(data)
    XSentinelGWNode.Super.UpdateWithServerData(self, data)
    self.DeadTime = data.DeadTime or 0
    self.AddRebuildTime = data.AddRebuildTime or 0
    self.NextMonsterBornTime = data.NextMstBornTime or 0
end

function XSentinelGWNode:GetNextMonsterBornTimeTip()
    return XUiHelper.GetTime(math.max(0, self.NextMonsterBornTime 
        - XTime.GetServerNowTimestamp()), XUiHelper.TimeFormatType.HOUR_MINUTE_SECOND)
end

-- 获取重建时间
function XSentinelGWNode:GetRebuildTime(addRebuildTime)
    if addRebuildTime == nil then addRebuildTime = 0 end
    addRebuildTime = self.AddRebuildTime + addRebuildTime
    return math.min(self.DeadTime + self.Config.RebuildTime + addRebuildTime
        , self.DeadTime + self.Config.RebuildMaxTime)
end

function XSentinelGWNode:GetRebuildTimeStr(addRebuildTime)
    local nowTime = XTime.GetServerNowTimestamp()
    return XUiHelper.GetTime(math.max(0, self:GetRebuildTime(addRebuildTime) 
        - nowTime), XUiHelper.TimeFormatType.HOUR_MINUTE_SECOND)
end

function XSentinelGWNode:GetIsOverMaxRebuildTime()
    return self.Config.RebuildTime + self.AddRebuildTime
        > self.Config.RebuildMaxTime
end

function XSentinelGWNode:GetMaxRebuildMaxTime()
    return self.DeadTime + self.Config.RebuildMaxTime
end

function XSentinelGWNode:GetOverRebuildTime()
    return self.Config.RebuildTime + self.AddRebuildTime - self.Config.RebuildMaxTime
end

-- 获取历史最高重建时间
function XSentinelGWNode:GetHistoryMaxRebuildTime()
    local damage = XDataCenter.GuildWarManager
        .GetBattleManager():GetMaxDamageByUID(self:GetUID(), XGuildWarConfig.FightRecordAliveType.Die)
    return self:GetRebuildTimeByDamage(damage)
end

-- 根据伤害获取重建时间
function XSentinelGWNode:GetRebuildTimeByDamage(value)
    return value / self.Config.MaxSubHp * self.Config.RebuildTimeFactor 
end

-- 获取重建进度
function XSentinelGWNode:GetRebuildProgress(addRebuildTime)
    return (XTime.GetServerNowTimestamp() - self.DeadTime) / (self:GetRebuildTime(addRebuildTime) - self.DeadTime)
end

-- 获取节点状态：正常，复活中，死亡
-- return : XGuildWarConfig.NodeStatusType
function XSentinelGWNode:GetStutesType()
    local result = XSentinelGWNode.Super.GetStutesType(self)
    if self:GetHP() <= 0 then
        return XGuildWarConfig.NodeStatusType.Revive
    end
    return result
end

function XSentinelGWNode:GetBornMonster()
    if self.BornMonster == nil then
        self.BornMonster = XGWEliteMonster.New(self.Config.EliteMonsterId)
    end
    return self.BornMonster
end

function XSentinelGWNode:GetStageId()
    if self:GetStutesType() == XGuildWarConfig.NodeStatusType.Revive then
        return XGuildWarConfig.GetCfgByIdKey(XGuildWarConfig.TableKey.Stage
           , self.Config.RebuildGuildWarStageId).StageId
    end
    return XSentinelGWNode.Super.GetStageId(self)
end

-- 检查是否能够扫荡
function XSentinelGWNode:CheckCanSweep(checkCostEnergy)    
    if self:GetStutesType() == XGuildWarConfig.NodeStatusType.Revive then
        if self:GetHistoryMaxRebuildTime() <= 0 then
            return false
        end
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
function XSentinelGWNode:GetMaxDamage()
    local aliveType = XGuildWarConfig.FightRecordAliveType.Die
    if self:GetHP() > 0 then
        aliveType = XGuildWarConfig.FightRecordAliveType.Alive
    end
    return XDataCenter.GuildWarManager
        .GetBattleManager():GetMaxDamageByUID(self.UID, aliveType)
end

-- 检查是否能够扫荡
function XSentinelGWNode:CheckCanSweep(checkCostEnergy)
    if self:GetMaxDamage() <= 0 then
        return false
    end
    if checkCostEnergy then
        return XDataCenter.GuildWarManager.GetCurrentActionPoint() >= self.Config.SweepCostEnergy
    end
    return true
end

function XSentinelGWNode:GetEliteMonsterBornInterval()
    return self.Config.EliteMonsterBornInterval
end

return XSentinelGWNode