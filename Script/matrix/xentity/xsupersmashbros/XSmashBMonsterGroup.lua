--===========================
--超限乱斗怪物组对象
--模块负责：吕天元
--===========================
---@class XSmashBMonsterGroup
local XSmashBMonsterGroup = XClass(nil, "XSmashBMonsterGroup")

function XSmashBMonsterGroup:Ctor(cfg)
    self:Reset()
    self.MonsterGroupCfg = cfg
end

function XSmashBMonsterGroup:Reset()
    self.IsClear = false
    self.HpLeft = 100
end

function XSmashBMonsterGroup:GetId()
    return self.MonsterGroupCfg and self.MonsterGroupCfg.Id
end

function XSmashBMonsterGroup:GetMonsterIdList()
    return self.MonsterGroupCfg and self.MonsterGroupCfg.MonsterIdList
end

function XSmashBMonsterGroup:GetAbility()
    return self.MonsterGroupCfg and self.MonsterGroupCfg.Ability
end

function XSmashBMonsterGroup:GetMonsterType()
    return self:GetMainMonster():GetMonsterType()
end

function XSmashBMonsterGroup:GetMonsterTypeName()
    return self:GetMainMonster():GetMonsterTypeName()
end

function XSmashBMonsterGroup:GetBuffList()
    local monsters = XDataCenter.SuperSmashBrosManager.GetMonstersByIdList(self:GetMonsterIdList())
    local buffList = {}
    local checkDic = {}
    for _, monster in pairs(monsters or {}) do
        local fightEventList = monster:GetFightEventList()
        for _, fightEventId in pairs(fightEventList or {}) do
            if not checkDic[fightEventId] then
                checkDic[fightEventId] = true
                table.insert(buffList, fightEventId)
            end
        end
    end
    return buffList
end

function XSmashBMonsterGroup:GetLimitStageId()
    local monsters = XDataCenter.SuperSmashBrosManager.GetMonstersByIdList(self:GetMonsterIdList())
    for _, monster in pairs(monsters or {}) do
        local limitStage = monster:GetLimitStageId()
        if limitStage > 0 then return limitStage end
    end
    return 0 
end
--=============
--检查怪物组是否限制在给定关卡Id的关卡中出战
--true 表示受限制不能出战  false 表示可以出战
--=============
function XSmashBMonsterGroup:CheckLimitStage(stageId)
    local limit = self:GetLimitStageId()
    if not limit or limit == 0 then return false end
    return stageId ~= limit
end

function XSmashBMonsterGroup:GetRewardId()
    return self.MonsterGroupCfg and self.MonsterGroupCfg.RewardId
end

function XSmashBMonsterGroup:GetPoint()
    return self.MonsterGroupCfg and self.MonsterGroupCfg.FirstScore
end

function XSmashBMonsterGroup:GetDropEnergy()
    return self.MonsterGroupCfg and self.MonsterGroupCfg.FramEnergy
end

function XSmashBMonsterGroup:GetDropLevelItem()
    return self.MonsterGroupCfg and self.MonsterGroupCfg.LevelItem
end

function XSmashBMonsterGroup:GetIcon()
    return self:GetMainMonster():GetIcon()
end

function XSmashBMonsterGroup:GetHalfBodyIcon()
    return self.MonsterGroupCfg and self.MonsterGroupCfg.HalfBodyIcon
end

function XSmashBMonsterGroup:GetOpenTime()
    return self.MonsterGroupCfg and self.MonsterGroupCfg.OpenTime
end

function XSmashBMonsterGroup:GetMainMonsterId()
    local ids = self:GetMonsterIdList()
    return ids and ids[1]
end

function XSmashBMonsterGroup:GetMainMonster()
    local mainId = self:GetMainMonsterId()
    local monster = XDataCenter.SuperSmashBrosManager.GetMonsterById(mainId)
    return monster
end

function XSmashBMonsterGroup:GetMainMonsterModelName()
    local mainId = self:GetMainMonsterId()
    local monster = XDataCenter.SuperSmashBrosManager.GetMonsterById(mainId)
    local modelName = monster:GetMonsterModelName()
    return modelName
end

function XSmashBMonsterGroup:GetMainMonsterModelScale()
    local mainId = self:GetMainMonsterId()
    local monster = XDataCenter.SuperSmashBrosManager.GetMonsterById(mainId)
    return monster:GetModelScale()
end

function XSmashBMonsterGroup:GetSubMonsterIds()
    local ids = self:GetMonsterIdList()
    local subIds = {}
    for i = 2, #ids do
        table.insert(subIds, ids[i])
    end
    return subIds
end

function XSmashBMonsterGroup:CheckIsClear()
    return self.IsClear
end

function XSmashBMonsterGroup:SetIsClear(value)
    self.IsClear = value
end
--==================
--获取剩余的生命值百分比
--==================
function XSmashBMonsterGroup:GetHpLeft()
    return self.HpLeft
end
--==================
--设置剩余的生命值百分比
--==================
function XSmashBMonsterGroup:SetHpLeft(value)
    self.HpLeft = value
end
--==================
--获取怪物组被挑战胜利的次数
--==================
function XSmashBMonsterGroup:GetWinCount()
    return self.WinCount or 0
end
--==================
--设置怪物组被挑战胜利的次数
--==================
function XSmashBMonsterGroup:SetWinCount(value)
    self.WinCount = value
    if value and value > 0 then
        self:SetIsClear(true)
    else
        self:SetIsClear(false)
    end
end

function XSmashBMonsterGroup:GetName()
    local mainMonster = self:GetMainMonster()
    return mainMonster and mainMonster:GetName() or "UnNamed"
end

---@param mode XSmashBMode
function XSmashBMonsterGroup:IsWinAmountEnoughToChallenge(mode)
    mode = mode or XDataCenter.SuperSmashBrosManager.GetPlayingMode()
    local winCount = mode:GetCurrentWinCount()
    local stageId = mode:GetStageId(self:GetId())
    if not stageId then
        return true
    end
    local needWinCount = XSuperSmashBrosConfig.GetCfgByIdKey(XSuperSmashBrosConfig.TableKey.SceneConfig, stageId).NeedWinCount
    return winCount >= needWinCount, needWinCount
end

return XSmashBMonsterGroup