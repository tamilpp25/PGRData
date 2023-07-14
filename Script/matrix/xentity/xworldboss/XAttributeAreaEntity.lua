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

function XAttributeAreaEntity:GetChallengeCount()--区域挑战次数
    return self.ChallengeCount
end

function XAttributeAreaEntity:GetScore()--区域积分
    return self.Score
end

function XAttributeAreaEntity:GetIsRewardGeted()--区域奖励是否领取
    return self.AreaRewardFlag
end

function XAttributeAreaEntity:GetCharacterDatas()--本区域的上一次的出战队列
    return self.CharacterDatas
end

function XAttributeAreaEntity:GetStageEntityDic()--该区域下所有关卡
    return self.StageEntityDic
end

function XAttributeAreaEntity:GetBossBuffList()--获得本区域所有biffId数组
    return self.BossBuffList
end

function XAttributeAreaEntity:GetGetedBossBuffList()--获得本区域已经获得的biffId数组
    return self.GetedBossBuffList
end

function XAttributeAreaEntity:GetGetedRobotList()--获得本区域已经获得的机器人数组
    return self.GetedRobotList
end

function XAttributeAreaEntity:GetFinishStageCount()--获得本区域已探索完成关卡数
    return self.FinishStageCount
end

function XAttributeAreaEntity:GetIsAreaFinish()--获得本区域已探索完成关卡数
    return self.FinishStageCount >= #self:GetStageIds()
end


function XAttributeAreaEntity:GetPrivateAttributeStageDatas()--获得私人属性关卡数据
    return self.PrivateData or {}
end

function XAttributeAreaEntity:GetGlobalAttributeStageDatas()--获得公共属性关卡数据
    return self.GlobalData or {}
end

function XAttributeAreaEntity:GetStageEntityById(id)--该区域某个关卡
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