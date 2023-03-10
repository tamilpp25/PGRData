local XAttributeAreaEntity = XClass(nil, "XAttributeAreaEntity")
local XAttributeStageEntity = require("XEntity/XWorldBoss/XAttributeStageEntity")
local CSTextManagerGetText = CS.XTextManager.GetText
function XAttributeAreaEntity:Ctor(id)
    self.Id = id
    self.PrivateData = {}
    self.GlobalData = {}

    self.ChallengeCount = 0
    self.AreaRewardFlag = false
    self.Score = 0
    self.CharacterDatas = {}

    self.StageEntityDic = {}
    for _, stageId in pairs(self:GetStageIds() or {}) do
        self.StageEntityDic[stageId] = XAttributeStageEntity.New(stageId)
    end
    self.BossBuffList = {}
    self.GetedBossBuffList = {}
    self.GetedRobotList = {}
    self.FinishStageCount = 0
end

function XAttributeAreaEntity:UpdateData(Data)
    for key, value in pairs(Data) do
        self[key] = value
    end
end

function XAttributeAreaEntity:UpdateStageEntityDic()
    self.BossBuffList = {}
    self.GetedBossBuffList = {}
    self.GetedRobotList = {}
    self.FinishStageCount = 0

    for _, stageData in pairs(self:GetPrivateAttributeStageDatas()) do
        self.StageEntityDic[stageData.Id]:UpdateData({ RewardFlag = stageData.RewardFlag })
    end

    for _, stageData in pairs(self:GetGlobalAttributeStageDatas()) do
        if self.StageEntityDic[stageData.Id] then
            self.StageEntityDic[stageData.Id]:UpdateData({ FinishCount = stageData.FinishCount })
        end
    end

    for _, stageEntity in pairs(self.StageEntityDic) do
        local isUnLock = true
        local lockDesc = ""
        if stageEntity:GetIsFinish() then
            for _, buffId in pairs(stageEntity:GetBuffIds() or {}) do
                local buffCfg = XWorldBossConfigs.GetBuffTemplatesById(buffId)
                if buffCfg.Type == XWorldBossConfigs.BuffType.Buff then
                    table.insert(self.GetedBossBuffList, buffId)
                elseif buffCfg.Type == XWorldBossConfigs.BuffType.Robot then
                    table.insert(self.GetedRobotList, buffId)
                end
            end
            self.FinishStageCount = self.FinishStageCount + 1
        else
            local name
            for _, stageId in pairs(stageEntity:GetPreStageId() or {}) do
                if stageId == 0 then
                    break
                end
                if not self.StageEntityDic[stageId]:GetIsFinish() then
                    local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
                    name = not name and stageCfg.Name or string.format("%s,%s", name, stageCfg.Name)
                    isUnLock = false
                end
            end
            lockDesc = name and CSTextManagerGetText("WorldBossStageLockText", name) or ""
        end

        for _, buffId in pairs(stageEntity:GetBuffIds() or {}) do
            local buffCfg = XWorldBossConfigs.GetBuffTemplatesById(buffId)
            if buffCfg.Type == XWorldBossConfigs.BuffType.Buff then
                table.insert(self.BossBuffList, buffId)
            end
        end
        local tmpData = {}
        tmpData.IsLock = not isUnLock
        tmpData.LockDesc = lockDesc
        stageEntity:UpdateData(tmpData)
    end

end

function XAttributeAreaEntity:GetCfg()
    return XWorldBossConfigs.GetAttributeAreaTemplatesById(self.Id)
end

function XAttributeAreaEntity:GetId()
    return self.Id
end

function XAttributeAreaEntity:GetChallengeCount()--??????????????????
    return self.ChallengeCount
end

function XAttributeAreaEntity:GetScore()--????????????
    return self.Score
end

function XAttributeAreaEntity:GetIsRewardGeted()--????????????????????????
    return self.AreaRewardFlag
end

function XAttributeAreaEntity:GetCharacterDatas()--????????????????????????????????????
    return self.CharacterDatas
end

function XAttributeAreaEntity:GetStageEntityDic()--????????????????????????
    return self.StageEntityDic
end

function XAttributeAreaEntity:GetBossBuffList()--?????????????????????biffId??????
    return self.BossBuffList
end

function XAttributeAreaEntity:GetGetedBossBuffList()--??????????????????????????????biffId??????
    return self.GetedBossBuffList
end

function XAttributeAreaEntity:GetGetedRobotList()--?????????????????????????????????????????????
    return self.GetedRobotList
end

function XAttributeAreaEntity:GetFinishStageCount()--???????????????????????????????????????
    return self.FinishStageCount
end

function XAttributeAreaEntity:GetIsAreaFinish()--???????????????????????????????????????
    return self.FinishStageCount >= #self:GetStageIds()
end


function XAttributeAreaEntity:GetPrivateAttributeStageDatas()--??????????????????????????????
    return self.PrivateData or {}
end

function XAttributeAreaEntity:GetGlobalAttributeStageDatas()--??????????????????????????????
    return self.GlobalData or {}
end

function XAttributeAreaEntity:GetStageEntityById(id)--?????????????????????
    if not self.StageEntityDic[id] then
        XLog.Error("AttributeArea Id:" .. self.Id .. " Is Not Have Stage id:" .. id)
    end
    return self.StageEntityDic[id]
end

function XAttributeAreaEntity:GetName()
    return self:GetCfg().Name
end

function XAttributeAreaEntity:GetEnglishName()
    return self:GetCfg().EnglishName
end

function XAttributeAreaEntity:GetMaxChallengeCount()
    return self:GetCfg().MaxChallengeCount
end

function XAttributeAreaEntity:GetFinishReward()
    return self:GetCfg().FinishReward
end

function XAttributeAreaEntity:GetBuffIds()
    return self:GetCfg().BuffId
end

function XAttributeAreaEntity:GetStageIds()
    return self:GetCfg().StageId
end

function XAttributeAreaEntity:GetStartStoryId()
    return self:GetCfg().StartStoryId
end

function XAttributeAreaEntity:GetAreaImg()
    return self:GetCfg().AreaImg
end

function XAttributeAreaEntity:GetAreaDesc()
    return self:GetCfg().AreaDesc
end

function XAttributeAreaEntity:GetPrefabName()
    return self:GetCfg().PrefabName
end

return XAttributeAreaEntity