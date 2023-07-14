local XReformEvolvableStage = require("XEntity/XReform/XReformEvolvableStage")
local XReformBaseStage = XClass(nil, "XReformBaseStage")

-- local MAX_DIFF_INDEX = 4

-- config : XReformConfigs.StageConfig
function XReformBaseStage:Ctor(config)
    -- XReformEvolvableStage
    self.EvolvableStageDic = {}
    -- XReformConfigs.StageConfig
    self.Config = config
    -- 当前难度
    self.CurDiffIndex = 1
    -- 未解锁的难度
    self.UnlockDiffIndex = 1
    -- stage配置表
    self.StageConfig = XDataCenter.FubenManager.GetStageCfg(config.Id)
    -- 引导Id
    self.Id = self.Config.Id
    -- 是否通关过
    self.IsPassed = false
end

-- data : XReformStageDb
function XReformBaseStage:InitWithServerData(data)
    -- 默认选择当前最大难度
    self.CurDiffIndex = data.CurDiffIndex + 1
    self.UnlockDiffIndex = data.UnlockDiffIndex + 1
    self.IsPassed = data.Pass
    local evolvableStage = nil
    -- difficultDb : ReformStageDifficultyDb
    for _, difficultDb in ipairs(data.DifficultyDbs) do
        evolvableStage = self:GetEvolvableStageById(difficultDb.Id)
        if evolvableStage == nil then
            XLog.Warning(string.format("服务器改造难度Id%s在本地配置找不到", difficultDb.Id))
        else
            evolvableStage:InitWithServerData(difficultDb)
            XDataCenter.ReformActivityManager.AddEvolvableMaxScore(self.Config.Id, evolvableStage:GetDifficulty(), difficultDb.Score)
        end
    end
end

function XReformBaseStage:UpdateIsPassed(value)
    self.IsPassed = value
end

function XReformBaseStage:UpdateUnlockDiffIndex(value)
    self.UnlockDiffIndex = value
end

function XReformBaseStage:SetCurrentDiffIndex(value)
    self.CurDiffIndex = value
end

function XReformBaseStage:GetUnlockDiffIndex()
    return self.UnlockDiffIndex
end

function XReformBaseStage:GetIsPlayReformUnlockEffect()
    local result = false
    -- local isPass = self:GetIsPassed()
    local isPlayed = XSaveTool.GetData(self:GetId() .. XPlayer.Id .. "GetIsPlayReformUnlockEffect" 
        .. XDataCenter.ReformActivityManager.GetId()) or false
    if not isPlayed then -- and isPass then
        result = true
        XSaveTool.SaveData(self:GetId() .. XPlayer.Id .. "GetIsPlayReformUnlockEffect"
        .. XDataCenter.ReformActivityManager.GetId(), true)
    end
    return result
end

function XReformBaseStage:GetIsShowEvolvableDiffTip()
    if self.CurDiffIndex >= self:GetMaxDiffCount() then
        return false
    end
    local isOpen = self:GetDifficultyIsOpen(self.CurDiffIndex + 1)
    local isTiped = XSaveTool.GetData(self:GetId() .. XPlayer.Id .. "GetIsShowEvolvableDiffTip" .. self.CurDiffIndex + 1
        .. XDataCenter.ReformActivityManager.GetId()) or false
    if isOpen and not isTiped then
        if self.CurDiffIndex == 1 and not self:GetIsPassed() then
            return false
        end
        XSaveTool.SaveData(self:GetId() .. XPlayer.Id .. "GetIsShowEvolvableDiffTip" .. self.CurDiffIndex + 1
        .. XDataCenter.ReformActivityManager.GetId(), true)
        return true, self:GetEvolvableStageByDiffIndex(self.CurDiffIndex + 1)
    end
    return false
end

function XReformBaseStage:GetEvolvableStageById(id)
    local evolvableStage = self.EvolvableStageDic[id]
    if evolvableStage == nil then
        local config = XReformConfigs.GetStageDiffConfigById(id)
        evolvableStage = XReformEvolvableStage.New(config)
        evolvableStage:SetSaveTeamDataKey("REFORM_" .. self:GetId() .. "_" .. evolvableStage:GetId())
        self.EvolvableStageDic[id] = evolvableStage
    end
    return evolvableStage
end

-- diffIndex : 从1开始，1是基础关卡信息配置
function XReformBaseStage:GetEvolvableStageByDiffIndex(diffIndex)
    if diffIndex <= 0 then return nil end
    diffIndex = diffIndex or self.CurDiffIndex
    return self:GetEvolvableStageById(self.Config.StageDiff[diffIndex])
end

function XReformBaseStage:GetId()
    return self.Config.Id
end

-- 名称
function XReformBaseStage:GetName()
    return self.Config.Name
end

function XReformBaseStage:GetShowNpcId()
    return self.Config.ShowNpcId
end

-- 是否锁定
function XReformBaseStage:GetIsUnlock()
    return XFunctionManager.CheckInTimeByTimeId(self.Config.OpenTimeId)
end

-- function XReformBaseStage:GetCurrentEvolvableStageTeamData()
--     local evolvableStage = self:GetCurrentEvolvableStage()
--     -- local memberGroup = evolvableStage:GetEvolvableGroupByType(XReformConfigs.EvolvableGroupType.Member)
--     return evolvableStage:GetTeamData()
-- end

function XReformBaseStage:GetCurrentEvolvableStageGroup(groupType)
    local evolvableStage = self:GetCurrentEvolvableStage()
    return evolvableStage:GetEvolvableGroupByType(groupType)
end

-- function XReformBaseStage:SaveCurrentEvolvableTeamData(teamData)
--     self:GetCurrentEvolvableStage():SaveTeamData(teamData)
-- end

-- 获取解锁时间信息
function XReformBaseStage:GetUnlockTimeStr()
    local startTime = XFunctionManager.GetStartTimeByTimeId(self.Config.OpenTimeId)
    local nowTime = XTime.GetServerNowTimestamp()
    return XUiHelper.GetTime(startTime - nowTime, XUiHelper.TimeFormatType.ACTIVITY)    
end

function XReformBaseStage:GetCurrentEvolvableStage()
    return self:GetEvolvableStageByDiffIndex(self.CurDiffIndex)
end

function XReformBaseStage:GetCurrentDifficulty()
    return self.CurDiffIndex 
end

function XReformBaseStage:GetFirstRewards()
    return XRewardManager.GetRewardList(self.StageConfig.FirstRewardId)
end

function XReformBaseStage:GetFirstRewardId()
    return self.StageConfig.FirstRewardId
end

-- 是否已通关
function XReformBaseStage:GetIsPassed()
    return self.IsPassed
end

function XReformBaseStage:GetDifficultyIsOpen(diffIndex)
    if diffIndex <= 0 then return true end
    local lastStage = self:GetEvolvableStageByDiffIndex(diffIndex - 1)
    if lastStage == nil then return true end
    local nextStage = self:GetEvolvableStageByDiffIndex(diffIndex)
    return lastStage:GetMaxScore() >= nextStage:GetUnlockScore()
end

-- 获取改造关卡数据
function XReformBaseStage:GetEvolvableStages()
    local result = {}
    local evolvableStage = nil
    for i = 2, #self.Config.StageDiff do
        evolvableStage = self:GetEvolvableStageById(self.Config.StageDiff[i])
        table.insert(result, evolvableStage)
    end
    return result
end

-- 累计积分
function XReformBaseStage:GetAccumulativeScore()
    local result = 0
    for _, evolvableStage in pairs(self.EvolvableStageDic) do
        result = result + evolvableStage:GetMaxScore()
    end
    return result
end

function XReformBaseStage:GetMaxChallengeScore(withTeamScore)
    local result = 0
    for _, evolvableStage in pairs(self.EvolvableStageDic) do
        result = result + evolvableStage:GetMaxChallengeScore(withTeamScore)
    end
    return result
end

function XReformBaseStage:GetEvolvableStageDic()
    return self.EvolvableStageDic
end

function XReformBaseStage:GetShowTips()
    return self.StageConfig.StarDesc
end

-- return : XFubenConfigs.StageFightEventDetails
function XReformBaseStage:GetShowFightEvents()
    local result = {}
    for _, fightEventId in ipairs(self.Config.ShowFightEventIds) do
        table.insert(result, XFubenConfigs.GetStageFightEventDetailsByStageFightEventId(fightEventId))
    end
    return result
end

function XReformBaseStage:GetMaxDiffCount()
    return XReformConfigs.GetBaseStageMaxDiffCount(self.Config.Id)
end

function XReformBaseStage:CheckIsCanReform()
    if self:GetMaxDiffCount() <= 1 then
        return true
    end
    return self:GetIsPassed()
end

function XReformBaseStage:CheckIsDefaultOpenTargetMember()
    return self:GetMaxDiffCount() <= 1
end

function XReformBaseStage:GetStageType()
    return self.Config.StageType
end

function XReformBaseStage:GetRecommendScore()
    return self.Config.RecommendScore
end

function XReformBaseStage:GetRecommendCharacterIcons()
    local result = {}
    for _, id in ipairs(self.Config.RecommendCharacterIds) do
        table.insert(result
            , XDataCenter.CharacterManager.GetCharBigHeadIcon(id))
    end
    return result
end

return XReformBaseStage