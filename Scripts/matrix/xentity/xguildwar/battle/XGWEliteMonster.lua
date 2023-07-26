-- 精英怪
local XGWEliteMonster = XClass(nil, "XGWEliteMonster")

function XGWEliteMonster:Ctor(id)
    self.Config = XGuildWarConfig.GetEliteMonsterConfig(id)
    self.MonsterPatrolConfig = XGuildWarConfig.GetCfgByIdKey(XGuildWarConfig.TableKey.MonsterPatrol, id)
    self.UID = 0
    self.CurrentHP = self.Config.HpMax
    self.MaxHP = self.Config.HpMax
    -- 当前路径索引
    self.CurrentRouteIndex = 0
    self.FightCount = 0
    self.DeadTime = 0
    -- 下一路径索引
    self.NextRouteIndex = 0
end

-- data : XGuildWarMonsterData
function XGWEliteMonster:UpdateWithServerData(data)
    self.UID = data.Uid
    self.CurrentHP = data.CurHp
    self.MaxHP = data.HpMax
    self.CurrentRouteIndex = data.CurNodeIdx
    self.FightCount = data.FightCount
    self.DeadTime = data.DeadTime
end

function XGWEliteMonster:UpdateCurrentRouteIndex(value)
    self.CurrentRouteIndex = value
end

function XGWEliteMonster:UpdateNextRouteIndex(value)
    self.NextRouteIndex = value
end

function XGWEliteMonster:GetIsDead()
    return self.CurrentHP <= 0
end

function XGWEliteMonster:UpdateDead(IsDead)--如果为true视为：死的复活，活的保持
    self.CurrentHP = IsDead and 0 or (self.CurrentHP > 0 and self.CurrentHP or 1)
end

function XGWEliteMonster:GetUID()
    return self.UID
end

function XGWEliteMonster:GetCurrentNodeId()
    return self.MonsterPatrolConfig.Routes[self.CurrentRouteIndex + 1]
end

function XGWEliteMonster:GetNextNodeId()
    return self.MonsterPatrolConfig.Routes[self.NextRouteIndex + 1]
end

-- 获取前进时间 
function XGWEliteMonster:GetForwardTimeStr()
    local refreshTime = XDataCenter.GuildWarManager.GetNextMapRefreshTime()
    local nowTime = XTime.GetServerNowTimestamp()
    return XUiHelper.GetTime(math.max(0, refreshTime - nowTime), XUiHelper.TimeFormatType.GUILDCD)
end

-- 已废弃
-- function XGWEliteMonster:GetBornTimeStr(day)
--     if day == nil then day = 1 end
--     local oclock = XGuildWarConfig.GetClientConfigValues("DayRefreshTime", "Float")[1]
--     local refreshTime = XTime.GetServerNextTargetTime(oclock + ((day - 1) * 24) )
--     local nowTime = XTime.GetServerNowTimestamp()
--     return XUiHelper.GetTime(math.max(0, refreshTime - nowTime), XUiHelper.TimeFormatType.HOUR_MINUTE_SECOND)
-- end

function XGWEliteMonster:GetIcon()
   return self.Config.Icon
end

function XGWEliteMonster:GetName()
    return self.Config.Name
end

-- 获取当前节点当场最高伤害
function XGWEliteMonster:GetMaxDamage()
    return XDataCenter.GuildWarManager.GetBattleManager()
        :GetMaxDamageByUID(self.UID)
end

function XGWEliteMonster:GetDamagePercent()
    return self.Config.DamagePercent
end

-- 获取百分比血量
function XGWEliteMonster:GetPercentageHP()
    return getRoundingValue((self:GetHP() / self:GetMaxHP()) * 100, 2)
end

function XGWEliteMonster:GetHP()
    return self.CurrentHP
end

function XGWEliteMonster:GetMaxHP()
    return self.MaxHP
end

function XGWEliteMonster:GetFightCostEnergy()
    return self.Config.FightCostEnergy
end

function XGWEliteMonster:GetSweepCostEnergy()
    return self.Config.SweepCostEnergy
end

function XGWEliteMonster:GetStageId()
    return XGuildWarConfig.GetCfgByIdKey(XGuildWarConfig.TableKey.Stage
        , self.Config.GuildWarStageId).StageId
end

-- 检查是否能够扫荡
function XGWEliteMonster:CheckCanSweep(checkCostEnergy)
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

return XGWEliteMonster