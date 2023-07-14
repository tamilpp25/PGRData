local XBossAreaEntity = XClass(nil, "XBossAreaEntity")
local XPhasesRewardEntity = require("XEntity/XWorldBoss/XPhasesRewardEntity")
function XBossAreaEntity:Ctor(id)
    self.Id = id
    self.LoseHp = 0
    self.MaxHp = 1
    self.ChallengeCount = 0
    self.HpRecord = 0
    self.IsLock = true-----------------------还差解锁更新检查
    self.CharacterDatas = {}
    self.GetedPhasesRewardIds = {}
    ---------------------------------------------------------
    self.PhasesRewardEntityDic = {}
    for _,phasesRewardId in pairs(self:GetPhasesRewardIds()) do
        self.PhasesRewardEntityDic[phasesRewardId] = XPhasesRewardEntity.New(phasesRewardId)
    end
end

function XBossAreaEntity:UpdateData(playerData)
    for key, value in pairs(playerData) do
        self[key] = value
    end
end

function XBossAreaEntity:UpdatePhasesReward()
    for _,rewardEntity in pairs(self.PhasesRewardEntityDic) do
        local isCanGet = self:GetBossHp() <= (rewardEntity:GetHpPercent() * 0.01 * self:GetTotalHp())
        local isGeted = self:GetIsGetedRewardById(rewardEntity:GetId())
        rewardEntity:UpdateData({IsCanGet = isCanGet,IsGeted = isGeted})
    end
end

function XBossAreaEntity:GetCfg()
    return XWorldBossConfigs.GetBossAreaTemplatesById(self.Id)
end

function XBossAreaEntity:GetId()
    return self.Id
end

function XBossAreaEntity:GetBossHp()
    return self:GetTotalHp() - self.LoseHp
end

function XBossAreaEntity:GetIsFinish()
    return self:GetBossHp() <= 0
end

function XBossAreaEntity:GetChallengeCount()
    return self.ChallengeCount
end

function XBossAreaEntity:GetHpRecord()
    return self.HpRecord
end

function XBossAreaEntity:GetIsLock()
    return self.IsLock
end

function XBossAreaEntity:GetTotalHp()
    return self.MaxHp ~= 0 and self.MaxHp or 1
end

function XBossAreaEntity:GetGetedPhasesRewardIds()
    return self.GetedPhasesRewardIds
end

function XBossAreaEntity:GetPhasesRewardEntityDic()--该区域下所有阶段奖励
    return self.PhasesRewardEntityDic
end

function XBossAreaEntity:GetCharacterDatas()
    return self.CharacterDatas
end

function XBossAreaEntity:GetIsGetedRewardById(id)
    for _,rewardId in pairs(self.GetedPhasesRewardIds) do
        if rewardId == id then
            return true
        end
    end
    return false
end

function XBossAreaEntity:GetRewardEntityById(id)--该区域某个阶段奖励
    if not self.PhasesRewardEntityDic[id] then
        XLog.Error("BossArea Id:"..self.Id.." Is Not Have PhasesReward id:"..id)
    end
    return self.PhasesRewardEntityDic[id]
end

function XBossAreaEntity:GetName()
    return self:GetCfg().Name
end

function XBossAreaEntity:GetOpenCount()
    return self:GetCfg().UnlockNeedStageCount
end

function XBossAreaEntity:GetMaxChallengeCount()
    return self:GetCfg().MaxChallengeCount
end

function XBossAreaEntity:GetStageId()
    return self:GetCfg().StageId
end

function XBossAreaEntity:GetPhasesRewardIds()
    return self:GetCfg().PhasesRewardId
end

function XBossAreaEntity:GetStartStoryId()
    return self:GetCfg().StartStoryId
end

function XBossAreaEntity:GetFinishStoryId()
    return self:GetCfg().FinishStoryId
end

function XBossAreaEntity:GetAreaImg()
    return self:GetCfg().AreaImg
end

function XBossAreaEntity:GetAreaLockImg()
    return self:GetCfg().AreaLockImg
end

function XBossAreaEntity:GetAreaDesc()
    return self:GetCfg().AreaDesc
end

function XBossAreaEntity:GetModelId()
    return self:GetCfg().ModelId
end

function XBossAreaEntity:GetBossTaskIds()
    return self:GetCfg().BossTaskId
end

function XBossAreaEntity:GetHpPercent()
    return self:GetBossHp() / self:GetTotalHp()
end

return XBossAreaEntity