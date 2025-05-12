local XFubenSimulationChallengeAgency = require("XModule/XBase/XFubenSimulationChallengeAgency")

---@class XFubenBossSingleAgency : XFubenSimulationChallengeAgency
---@field private _Model XFubenBossSingleModel
local XFubenBossSingleAgency = XClass(XFubenSimulationChallengeAgency, "XFubenBossSingleAgency")

local METHOD_NAME = {
    GetSelfRank = "BossSingleRankInfoRequest",
    GetRankData = "BossSingleGetRankRequest",
    GetReward = "BossSingleGetRewardRequest",
    GetAllReward = "BossSingleGetAllRewardRequest",
    AutoFight = "BossSingleAutoFightRequest",
    SaveScore = "BossSingleSaveScoreRequest",
    ChooseLevelType = "BossSingleSelectLevelTypeRequest",
    GetChallengeSelfRank = "BossSingleChallengeRankInfoRequest",
    GetChallengeRankData = "BossSingleGetChallengeRankRequest",
}

function XFubenBossSingleAgency:OnInit()
    -- 初始化一些变量
    self:RegisterChapterAgency()
    self:RegisterFuben(XEnumConst.FuBen.StageType.BossSingle)

    self._LastSyncServerRankTimes = {}
    self._LastSyncServerBossRankTimes = {}
    self._LastSyncServerChallengeRankTimes = {}
    self._SyncServerSecond = 20
    self.ExChapterType = self:ExGetChapterType()
end

function XFubenBossSingleAgency:InitRpc()
    -- 实现服务器事件注册
    -- XRpc.XXX
    XRpc.NotifyFubenBossSingleData = Handler(self, self.OnNotifyFubenBossSingleData)
    XRpc.NotifyBossSingleRankInfo = Handler(self, self.OnNotifyBossSingleRankInfo)
    XRpc.NotifyBossSingleChallengeCount = Handler(self, self.OnNotifyBossSingleChallengeCount)
end

function XFubenBossSingleAgency:InitEvent()
    -- 实现跨Agency事件注册
    -- self:AddAgencyEvent()
end

function XFubenBossSingleAgency:OnRelease()
    self._LastSyncServerRankTimes = {}
    self._LastSyncServerBossRankTimes = {}
    self._LastSyncServerChallengeRankTimes = {}
end

-- region Getter/Setter

function XFubenBossSingleAgency:IsBossSingleDataEmpty()
    local bossSingleData = self:GetBossSingleData()

    return bossSingleData:IsBossSingleEmpty()
end

function XFubenBossSingleAgency:OnActivityEnd()
    local data = self:GetBossSingleData()

    XUiManager.TipText("BossOnlineOver")
    XLuaUiManager.RunMain()
    data:SetIsNeedReset(false)
end

function XFubenBossSingleAgency:UpdateBossSingleData(data)
    self._Model:UpdateBossSingleData(data.FubenBossSingleData)
    self._Model:UpdateBossSingleChallenge()

    local bossSingleData = self:GetBossSingleData()

    XCountDown.CreateTimer(self._Model:GetResetCountDownName(), bossSingleData:GetBossSingleRemainTime())

    if bossSingleData:GetIsNeedReset() then
        XEventManager.DispatchEvent(XEventId.EVENT_FUBEN_SINGLE_BOSS_RESET)
    end

    self._Model:UpdateTrailStageMap()
    if self:IsInLevelTypeChooseAble() then
        XEventManager.DispatchEvent(XEventId.EVENT_NEW_ACTIVITY_CALENDAR_UPDATE)
    end
end

---@return XBossSingle
function XFubenBossSingleAgency:GetBossSingleData()
    return self._Model:GetBossSingleData()
end

---@return XBossSingleChallenge
function XFubenBossSingleAgency:GetChallengeSingleData()
    return self._Model:GetBossSingleChallengeData()
end

function XFubenBossSingleAgency:GetMaxRankCount()
    return self._Model:GetMaxRankCount()
end

function XFubenBossSingleAgency:GetChallengeCount()
    local levelType = self:GetBossSingleData():GetBossSingleLevelType()
    local levelTypeConfig = self._Model:GetBossSingleGradeConfigByLevelType(levelType)

    if XTool.IsTableEmpty(levelTypeConfig) then
        XLog.ErrorTableDataNotFound("XFubenBossSingleAgency:GetChallengeCount", "levelTypeCfg",
            "Share/Fuben/BossSingle/BossSingleGrade.tab", "levelType", tostring(levelType))
        return 0
    end

    if XTime.CheckWeekend() then
        return levelTypeConfig.WeekChallengeCount
    else
        return levelTypeConfig.ChallengeCount
    end
end

function XFubenBossSingleAgency:GetAllChooseBossList()
    return self:GetBossSingleData():GetAllChooseAbleBossList()
end

function XFubenBossSingleAgency:IsBossSingleOpen()
    local isOpen = XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.FubenChallengeBossSingle)

    return isOpen
end

function XFubenBossSingleAgency:IsBossSingleTrial()
    return self._Model:GetFightStageType() == XEnumConst.BossSingle.StageType.Trial
end

function XFubenBossSingleAgency:IsInLevelTypeChooseAble()
    local bossSingleData = self:GetBossSingleData()

    return bossSingleData:GetBossSingleLevelType() == XEnumConst.BossSingle.LevelType.ChooseAble
end

function XFubenBossSingleAgency:IsInLevelTypeExtreme()
    local bossSingleData = self:GetBossSingleData()
    local levelType = bossSingleData:GetBossSingleLevelType()
    local gradeType = self._Model:GetBossSingleGradeTypeByLevelType(levelType)

    return gradeType == XEnumConst.BossSingle.LevelType.Extreme
end

function XFubenBossSingleAgency:GetActivityNo()
    local data = self:GetBossSingleData()

    return data:GetBossSingleActivityNo()
end

function XFubenBossSingleAgency:GetBossNameInfo(bossId, stageId)
    local stageName = ""
    local chapterName = ""
    local sectionInfo = self._Model:GetBossSectionInfoById(bossId)

    for i = 1, #sectionInfo do
        if sectionInfo[i].StageId == stageId then
            local stageCfg = XMVCA.XFuben:GetStageCfg(stageId)
            local curBossStageCfg = self._Model:GetBossSingleStageConfigByStageId(sectionInfo[i].StageId)

            stageName = stageCfg.Name
            chapterName = curBossStageCfg.BossName
        end
    end
    return chapterName, stageName
end

function XFubenBossSingleAgency:GetMaxStamina()
    local data = self:GetBossSingleData()
    local levelType = data:GetBossSingleLevelType()
    local staminaCount = self._Model:GetBossSingleGradeStaminaCountByLevelType(levelType)

    if not staminaCount then
        XLog.ErrorTableDataNotFound("XFubenBossSingleAgency:GetMaxStamina", "levelTypeCfg",
            "Share/Fuben/BossSingle/BossSingleGrade.tab", "levelType", tostring(levelType))
        return 0
    end

    return staminaCount
end

function XFubenBossSingleAgency:GetCharacterChallengeCount(characterId)
    local data = self:GetBossSingleData()
    local points = data:GetBossSingleCharacterPointMap()

    return points[characterId] or 0
end

function XFubenBossSingleAgency:GetRankSpecialIcon(number, levelType)
    if not levelType then
        local data = self:GetBossSingleData()

        levelType = data:GetBossSingleLevelType()
    end

    local configs = self:GetRankRewardConfig(levelType)

    if not configs[number] then
        XLog.Error(string.format("表BossSignleReward.tab不存在当前LevelType的RankIcon！索引:%d LevelType:%d",
            number, levelType))
        return
    end

    return configs[number].RankIcon
end

function XFubenBossSingleAgency:GetRankRewardConfig(levelType)
    local data = self:GetBossSingleData()
    local targetId = data:GetBossSingleRewardGroupId()
    local rewardConfig = {}
    local configs = self._Model:GetRankRewardConfigByLevelType(levelType)

    for _, config in pairs(configs) do
        if self:CheckLevelTypeHasRankReward(levelType) then
            if config.RewardGroupId == targetId then
                table.insert(rewardConfig, config)
            end
        else
            table.insert(rewardConfig, config)
        end
    end

    return rewardConfig
end

function XFubenBossSingleAgency:GetScoreRewardConfig(levelType)
    local scoreReward = {}
    local configs = self._Model:GetScoreRewardConfigByLevelType(levelType)
    local data = self:GetBossSingleData()

    if configs then
        for i, config in pairs(configs) do
            if config.RewardGroupId == data:GetBossSingleRewardGroupId() then
                scoreReward[#scoreReward + 1] = config
            end
        end
    end

    return scoreReward
end

function XFubenBossSingleAgency:GetResetCountDownName()
    return self._Model:GetResetCountDownName()
end

function XFubenBossSingleAgency:GetFeatureIdsByFeatureGroupId(groupId)
    return self._Model:GetBossSingleChallengeFeatureGroupFeatureIdsById(groupId)
end

function XFubenBossSingleAgency:GetFeatureConfigById(id)
    return self._Model:GetBossSingleChallengeFeatureConfigById(id)
end

function XFubenBossSingleAgency:GetStageTotalScoreByStageId(stageId)
    return self._Model:GetBossSingleStageScoreByStageId(stageId)
end

function XFubenBossSingleAgency:GetStageIdsBySectionId(sectionId)
    local id = self._Model:GetBossSectionConfigIdBySectionId(sectionId)

    return self._Model:GetBossSingleSectionStageIdById(id)
end

function XFubenBossSingleAgency:GetStageIdsById(id)
    return self._Model:GetBossSingleSectionStageIdById(id)
end

function XFubenBossSingleAgency:GetSectionIdById(id)
    if not XTool.IsNumberValid(id) then
        return 0
    end

    return self._Model:GetBossSingleSectionSectionIdById(id)
end

function XFubenBossSingleAgency:GetModelIdByStageId(stageId)
    return self._Model:GetBossSingleStageModelIdByStageId(stageId)
end

function XFubenBossSingleAgency:GetLevelTypeByGradeType(gradeType)
    local configs = self._Model:GetBossSingleGradeConfigs()
    local bossSingle = self:GetBossSingleData()

    for levelType, config in pairs(configs) do
        if bossSingle:IsCurrentConfig(config) and gradeType == config.GradeType then
            return levelType
        end
    end

    return 0
end

function XFubenBossSingleAgency:GetAllStageCount()
    local count = 0

    if not self:IsBossSingleDataEmpty() then
        local data = self:GetBossSingleData()
        local bossList = data:GetBossSingleBossList()

        for k, bossId in pairs(bossList) do
            local sectionInfo = self._Model:GetBossSectionInfoById(bossId)

            if sectionInfo then
                count = count + #sectionInfo
            end
        end

    end

    return count
end

function XFubenBossSingleAgency:GetNotPassStageCount()
    local count = 0

    if not self:IsBossSingleDataEmpty() then
        local data = self:GetBossSingleData()
        local bossList = data:GetBossSingleBossList()

        for k, bossId in pairs(bossList) do
            count = count + self:GetBossNotPassStageCount(bossId)
        end

    end

    return count
end

function XFubenBossSingleAgency:GetBossNotPassStageCount(bossId)
    local sectionInfo = self._Model:GetBossSectionInfoById(bossId)
    local count = 0

    if sectionInfo then
        for i = 1, #sectionInfo do
            local stageInfo = XMVCA.XFuben:GetStageInfo(sectionInfo[i].StageId)

            --- 检查boss全部完成时不检查隐藏关
            if not stageInfo.Passed then
                count = count + 1
            end
        end
    end

    return count
end

function XFubenBossSingleAgency:GetFreatureIdByStageId(targetStageId)
    local challengeData = self:GetChallengeSingleData()

    if challengeData:GetIsEmpty() then
        return 0
    end

    local feature = challengeData:GetFeatureByStageId(targetStageId)

    if feature then
        return feature:GetFeatureId()
    else
        return 0
    end
end

function XFubenBossSingleAgency:GetShowRecommendIds(featureId)
    return self._Model:GetBossSingleChallengeFeatureShowRecommendIdsById(featureId)
end

function XFubenBossSingleAgency:GetRelieveTeamAstrict()
    return self._Model:GetRelieveTeamAstrict() == 1
end

function XFubenBossSingleAgency:GetCurrentFeatureId()
    return self._Model:GetCurrentFeatureId()
end

-- endregion

-- region Check

function XFubenBossSingleAgency:CheckLevelTypeHasRankReward(levelType)
    local bossSingle = self:GetBossSingleData()

    if bossSingle:IsNewVersion() then
        return levelType == XEnumConst.BossSingle.LevelType.Challenge
    end

    return true
end

function XFubenBossSingleAgency:CheckBossAllPassed(bossId)
    local sectionInfo = self._Model:GetBossSectionInfoById(bossId)

    if sectionInfo then
        for i = 1, #sectionInfo do
            local stageInfo = XMVCA.XFuben:GetStageInfo(sectionInfo[i].StageId)
            local bossStageInfo = self._Model:GetBossSingleStageConfigByStageId(sectionInfo[i].StageId)

            --- 检查boss全部完成时不检查隐藏关
            if not stageInfo.Passed and bossStageInfo.DifficultyType ~= XEnumConst.BossSingle.DifficultyType.Hide then
                return false
            end
        end
    end

    return true
end

--- 检查凹分区是否有两个及以上计分
function XFubenBossSingleAgency:CheckChallengeFinished()
    local challengeData = self:GetChallengeSingleData()

    if challengeData:GetIsEmpty() then
        return true
    end

    return challengeData:GetRecordFeatureCount() >= 2
end

function XFubenBossSingleAgency:CheckAllPassed()
    if not self:IsBossSingleDataEmpty() then
        local data = self:GetBossSingleData()
        local bossList = data:GetBossSingleBossList()

        for k, bossId in pairs(bossList) do
            if not self:CheckBossAllPassed(bossId) then
                return false
            end
        end

        return true
    end

    return false
end

--- 检查奖励是否还有奖励需要领取
function XFubenBossSingleAgency:CheckRewardRedHint()
    local data = self:GetBossSingleData()
    local index = data:GetBossSingleLevelType()
    local configs = self:GetScoreRewardConfig(index)

    if (not configs) or #configs == 0 then
        return -1
    end

    local totalScore = data:GetBossSingleTotalScore()
    local rewardIds = data:GetBossSingleRewardIdList()

    for _, v in pairs(configs) do
        local canGet = totalScore >= v.Score
        local got = false

        if canGet then
            for _, id in pairs(rewardIds) do
                if id == v.Id then
                    got = true
                    break
                end
            end

            if not got then
                return 1
            end
        end
    end

    return -1
end

function XFubenBossSingleAgency:CheckChallengeRedPoint()
    local isFinished = self:CheckChallengeFinished()

    return not isFinished
end

function XFubenBossSingleAgency:CheckAcitvityEnd(stageId)
    local data = self:GetBossSingleData()

    local stageType = XMVCA.XFuben:GetStageType(stageId)
    return stageType == XEnumConst.FuBen.StageType.BossSingle and data:GetIsNeedReset()
end

function XFubenBossSingleAgency:CheckShowRecommend(featureId)
    local recommendIds = self._Model:GetBossSingleChallengeFeatureShowRecommendIdsById(featureId)
    
    return not XTool.IsTableEmpty(recommendIds)
end

function XFubenBossSingleAgency:CheckCanChallengeRecord()
    local bossSingle = self:GetBossSingleData()
    local recordTime = bossSingle:GetBossSingleChallengeDeleteRecordTime()

    if XTool.IsNumberValid(recordTime) then
        local nowTime = XTime.GetServerNowTimestamp()
        local endTime = recordTime + self._Model:GetChallengeRecordCD()
        
        return endTime <= nowTime
    end

    return true
end

-- endregion

-- region OpenUi

function XFubenBossSingleAgency:OpenBossSingleView(skipId)
    if not self:IsBossSingleDataEmpty() then
        local levelType = self:GetBossSingleData():GetBossSingleLevelType()

        if not XMVCA.XSubPackage:CheckSubpackage(XEnumConst.FuBen.ChapterType.BossSingle, levelType) then
            return false
        end

        -- 获取异步跳转结果Id
        local skipResultId = XFunctionManager.GetNewResultId()
        
        self:RequestSelfRank(function() 
            self:OpenMainUi(skipId, skipResultId)
        end)
        
        return skipResultId
    end
    
    return false
end

function XFubenBossSingleAgency:OpenMainUi(skipId, skipResultId)
    if not self:IsBossSingleDataEmpty() then
        local data = self:GetBossSingleData()

        data:SetIsNeedReset(false)
        XLuaUiManager.Open("UiFubenBossSingle", data:GetBossSingleBossList())

        XFunctionManager.AcceptResult(skipResultId, true)
    else
        XFunctionManager.AcceptResult(skipResultId, false)
    end

    
end

function XFubenBossSingleAgency:OpenTrialUi()
    if not self:IsBossSingleDataEmpty() then
        local data = self:GetBossSingleData()

        data:SetIsNeedReset(false)
        XLuaUiManager.Open("UiFubenBossSingleTrial")
    end
end

function XFubenBossSingleAgency:OpenChooseUi()
    local highBossList, extremeBossList = self:GetAllChooseBossList()

    if not highBossList or not extremeBossList then
        return false
    end

    XLuaUiManager.Open("UiFubenBossSingleChooseLevelType", highBossList, extremeBossList)
    return true
end

-- endregion

-- region 副本入口相关

function XFubenBossSingleAgency:ExGetChapterType()
    return XEnumConst.FuBen.ChapterType.BossSingle
end

function XFubenBossSingleAgency:ExGetProgressTip()
    local progress = ""
    local data = self:GetBossSingleData()

    if not self:ExGetIsLocked() then
        if data:IsNewVersion() then
            if self:IsInLevelTypeChooseAble() then
                progress = XUiHelper.GetText("BossSingleProgressChooseable")
            elseif not data:CheckHasChallengeData() then
                local stageCount = self:GetNotPassStageCount()
                local allStageCount = self:GetAllStageCount()
                
                progress = XUiHelper.GetText("BossSingleProgress", allStageCount - stageCount, allStageCount)
            else
                local challengeData = self:GetChallengeSingleData()
                local count = challengeData:GetRecordingFeatureCount()
                
                progress = XUiHelper.GetText("BossSingleProgress", count, 2)
            end
        else
            if self:IsInLevelTypeChooseAble() then
                progress = XUiHelper.GetText("BossSingleProgressChooseable")
            else
                local allCount = self:GetChallengeCount()
                local bossSingleData = self:GetBossSingleData()
                local challengeCount = bossSingleData:GetBossSingleChallengeCount()
    
                progress = XUiHelper.GetText("BossSingleProgress", challengeCount, allCount)
            end
        end
    end

    return progress
end

function XFubenBossSingleAgency:ExGetRunningTimeStr()
    if not self:IsBossSingleDataEmpty() then
        local data = self:GetBossSingleData()
        local remainTime = data:GetBossSingleEndTime() - XTime.GetServerNowTimestamp()
        local timeText = XUiHelper.GetTime(remainTime, XUiHelper.TimeFormatType.CHALLENGE)

        return XUiHelper.GetText("BossSingleLeftTimeIcon", timeText)
    end

    return ""
end

function XFubenBossSingleAgency:ExCheckIsFinished(cb)
    local result = true
    local data = self:GetBossSingleData()
    local isLocked = self:ExGetIsLocked()

    if isLocked then
        result = false
    else
        if self:IsInLevelTypeChooseAble() then
            ---未选区状态
            result = false
        elseif self:IsInLevelTypeExtreme() then
            local conditions = {
                "CONDITION_BOSS_SINGLE_REWARD",
            }
            local isCouldChallenge = data:GetBossSingleChallengeCount() < self:GetChallengeCount()
            local isAllPass = self:CheckAllPassed()
            local isChallengeLevelFinished = self:CheckChallengeFinished()
            local isHasReward = XRedPointManager.CheckConditions(conditions)

            if data:CheckHasChallengeData() then
                ---终极区解锁凹分区(挑战次数用尽 or 所有关卡通关) 并且所有奖励已经领取， 且凹分区有两个计分关卡
                if (isCouldChallenge and not isAllPass) or isHasReward or not isChallengeLevelFinished then
                    result = false
                end
            else
                ---终极区未解锁凹分区(挑战次数用尽 or 所有关卡通关) 并且所有奖励已经领取
                if (isCouldChallenge and not isAllPass) or isHasReward then
                    result = false
                end
            end
        else
            local conditions = {
                "CONDITION_BOSS_SINGLE_REWARD",
            }
            local isCouldChallenge = data:GetBossSingleChallengeCount() < self:GetChallengeCount()
            local isAllPass = self:CheckAllPassed()
            local isHasReward = XRedPointManager.CheckConditions(conditions)

            ---非终极区(挑战次数用尽 or 所有关卡通关) 并且所有奖励已经领取
            if (isCouldChallenge and not isAllPass) or isHasReward then
                result = false
            end
        end
    end

    if cb then
        cb(result)
    end

    self.IsClear = result

    return result
end

function XFubenBossSingleAgency:ExOpenMainUi()
    if XFunctionManager.DetectionFunction(self:ExGetFunctionNameType()) then
        if self:IsInLevelTypeChooseAble() then
            self:OpenChooseUi()
            return
        end

        self:OpenBossSingleView()
    end
end

--- 获取倒计时(周历专用)
function XFubenBossSingleAgency:ExGetCalendarRemainingTime()
    local data = self:GetBossSingleData()
    local endTime = data:GetBossSingleEndTime()

    if not XTool.IsNumberValid(endTime) then
        return ""
    end

    local remainTime = endTime - XTime.GetServerNowTimestamp()

    if remainTime < 0 then
        remainTime = 0
    end

    local timeText = XUiHelper.GetTime(remainTime, XUiHelper.TimeFormatType.NEW_CALENDAR)

    return XUiHelper.GetText("UiNewActivityCalendarEndCountDown", timeText)
end

--- 获取解锁时间(周历专用)
function XFubenBossSingleAgency:ExGetCalendarEndTime()
    local data = self:GetBossSingleData()
    local endTime = data:GetBossSingleEndTime()

    if not XTool.IsNumberValid(endTime) then
        return 0
    end

    return endTime
end

--- 是否在周历里显示
function XFubenBossSingleAgency:ExCheckShowInCalendar()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.FubenChallengeBossSingle, nil, true) then
        return false
    end
    
    local data = self:GetBossSingleData()
    local endTime = data:GetBossSingleEndTime()

    if not XTool.IsNumberValid(endTime) then
        return false
    end
    if endTime - XTime.GetServerNowTimestamp() <= 0 then
        return false
    end
    if XTool.IsNumberValid(data:GetBossSingleActivityNo()) then
        return true
    end

    return false
end

--- 是否显示提示信息(周历专用)
function XFubenBossSingleAgency:ExCheckWeekIsShowTips()
    if self:IsInLevelTypeChooseAble() then
        return true
    end

    return false
end

-- endregion

-- region 战斗接口

--function XFubenBossSingleAgency:InitStageInfo()
--    local sectionConfigs = self._Model:GetBossSingleSectionConfigs()
--
--    for _, sectionCfg in pairs(sectionConfigs) do
--        for i = 1, #sectionCfg.StageId do
--            local bossStageCfg = self._Model:GetBossSingleStageConfigByStageId(sectionCfg.StageId[i])
--            local stageInfo = XMVCA.XFuben:GetStageInfo(bossStageCfg.StageId)
--
--            stageInfo.BossSectionId = sectionCfg.SectionId
--            stageInfo.Type = XEnumConst.FuBen.StageType.BossSingle
--        end
--    end
--end

function XFubenBossSingleAgency:GetBossSectionId(stageId)
    local sectionConfigs = self._Model:GetBossSingleSectionConfigs()

    for _, sectionCfg in pairs(sectionConfigs) do
        for i = 1, #sectionCfg.StageId do
            local bossStageCfg = self._Model:GetBossSingleStageConfigByStageId(sectionCfg.StageId[i])
            if bossStageCfg.StageId == stageId then
                return sectionCfg.SectionId
            end
        end
    end
end

function XFubenBossSingleAgency:CheckPreFight()
    if self._Model:GetFightStageType() == XEnumConst.BossSingle.StageType.Challenge then
        return true
    end
    
    local curCount = self:GetBossSingleData():GetBossSingleChallengeCount()
    local allCount = self:GetChallengeCount()

    if allCount - curCount <= 0 and not self:IsBossSingleTrial() then
        local msg = CS.XTextManager.GetText("FubenChallengeCountNotEnough")

        XUiManager.TipMsg(msg)

        return false
    end

    return true
end

function XFubenBossSingleAgency:PreFight(stage, teamId, isAssist, challengeCount, challengeId)
    local isArenaOnline = XDataCenter.ArenaOnlineManager.CheckStageIsArenaOnline(stage.StageId)
    local preFight = {
        CardIds = {},
        StageId = stage.StageId,
        IsHasAssist = isAssist and true or false,
        ChallengeCount = challengeCount or 1,
        BossSingleStageType = self._Model:GetFightStageType(),
    }

    -- 如果有试玩角色，则不读取玩家队伍信息
    if not stage.RobotId or #stage.RobotId <= 0 then
        local teamData = XDataCenter.TeamManager.GetTeamData(teamId)
        for _, v in pairs(teamData) do
            table.insert(preFight.CardIds, v)
        end
        preFight.CaptainPos = XDataCenter.TeamManager.GetTeamCaptainPos(teamId)
        preFight.FirstFightPos = XDataCenter.TeamManager.GetTeamFirstFightPos(teamId)
    end
    if isArenaOnline then
        preFight.StageLevel = XDataCenter.ArenaOnlineManager.GetSingleModeDifficulty(challengeId, true)
    end

    return preFight
end

--- 胜利 & 奖励界面
function XFubenBossSingleAgency:ShowReward(winData)
    if XMVCA.XFuben:CheckHasFlopReward(winData) then
        XLuaUiManager.Open("UiFubenFlopReward", function()
            XLuaUiManager.PopThenOpen("UiSettleWinSingleBoss", winData)
        end, winData)
    else
        XLuaUiManager.Open("UiSettleWinSingleBoss", winData)
    end
end

--- 为独立判断普通囚笼和体验囚笼的Stage解锁增加的Handler
function XFubenBossSingleAgency:CheckUnlockByStageId(stageId)
    if self:IsBossSingleTrial() then
        return true
    end
end

-- endregion

-- region Notify

function XFubenBossSingleAgency:OnNotifyFubenBossSingleData(data)
    self:UpdateBossSingleData(data)
    self._Model:SetChooseAbleBossListMap(data.BossListDict)
    XEventManager.DispatchEvent(XEventId.EVENT_FUBEN_SINGLE_BOSS_SYNC)
end

function XFubenBossSingleAgency:OnNotifyBossSingleRankInfo(data)
    if data.RankType == XEnumConst.BossSingle.RankType.Normal then
        self._Model:UpdateBossSingleSelfRankInfo(data)
    else
        self._Model:UpdateChallengeSelfRankInfo(data)
    end
    XEventManager.DispatchEvent(XEventId.EVENT_FUBEN_SINGLE_BOSS_RANK_SYNC)
end

function XFubenBossSingleAgency:OnNotifyBossSingleChallengeCount(data)
    local bossSingleData = self:GetBossSingleData()

    bossSingleData:SetChallengeCount(data.ChallengeCount)
end

-- endregion

-- region 协议

function XFubenBossSingleAgency:RequestSelfRank(callback, sectionId)
    XNetwork.Call(METHOD_NAME.GetSelfRank, {
        SectionId = sectionId or 0,
    }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        self._Model:UpdateBossSingleSelfRankInfo(res)

        if callback then
            callback()
        end
    end)
end

function XFubenBossSingleAgency:RequestChallengeSelfRank(callback, stageId)
    XNetwork.Call(METHOD_NAME.GetChallengeSelfRank, {
        StageId = stageId or 0,
    }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        self._Model:UpdateChallengeSelfRankInfo(res)

        if callback then
            callback()
        end
    end)
end

-- 自动战斗
function XFubenBossSingleAgency:RequestAutoFight(stagedId, cb)
    local req = {
        StageId = stagedId,
    }

    XNetwork.Call(METHOD_NAME.AutoFight, req, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        if cb then
            cb(res.Supply > 0)
        end
    end)
end

function XFubenBossSingleAgency:RequestChooseLevelType(levelType)
    if not levelType then
        return
    end

    local req = {
        LevelId = levelType,
    }
    XNetwork.Call(METHOD_NAME.ChooseLevelType, req, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        self:UpdateBossSingleData(res)
        self:OpenBossSingleView()
    end)
end

function XFubenBossSingleAgency:RequestGetRankReward(rewardId, cb)
    local req = {
        Id = rewardId,
    }
    XNetwork.Call(METHOD_NAME.GetReward, req, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        local data = self:GetBossSingleData()

        data:AddBossSingleRewardId(rewardId)

        if cb then
            cb(res.RewardGoodsList)
        end
    end)
end

function XFubenBossSingleAgency:RequestGetAllRankReward(cb)
    XNetwork.Call(METHOD_NAME.GetAllReward, nil, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        if cb then
            cb(res.RewardGoodsList)
        end
    end)
end

function XFubenBossSingleAgency:RequestRankData(callback, levelType, isForce)
    local now = XTime.GetServerNowTimestamp()

    if not isForce then
        if self._LastSyncServerRankTimes[levelType] and self._LastSyncServerRankTimes[levelType] + self._SyncServerSecond
            > now then
            local rankData = self._Model:GetRankDataCacheByLevelType(levelType)
            
            if callback then
                if rankData then
                    callback(rankData)
                    return
                end
            else
                return
            end
        end
    end

    local req = {
        Level = levelType,
        SectionId = 0,
    }
    XNetwork.Call(METHOD_NAME.GetRankData, req, function(response)
        if response.Code ~= XCode.Success then
            XUiManager.TipCode(response.Code)
            return
        end

        self._LastSyncServerRankTimes[levelType] = now
        self._Model:UpdateRankDataCache(levelType, response)
        if callback then
            callback(self._Model:GetRankDataCacheByLevelType(levelType))
        end
    end)
end

function XFubenBossSingleAgency:RequestBossRankData(callback, levelType, bossId, isForce)
    local now = XTime.GetServerNowTimestamp()

    if not isForce then
        if self._LastSyncServerBossRankTimes[levelType] and self._LastSyncServerBossRankTimes[levelType][bossId]
            and self._LastSyncServerBossRankTimes[levelType][bossId] + self._SyncServerSecond > now then
            local rankData = self._Model:GetBossRankDataCacheByTypeAndBossId(levelType, bossId)
            
            if callback then
                if rankData then
                    callback(rankData)
                    return
                end
            else
                return
            end
        end
    end

    local req = {
        Level = levelType,
        SectionId = bossId,
    }
    XNetwork.Call(METHOD_NAME.GetRankData, req, function(response)
        if response.Code ~= XCode.Success then
            XUiManager.TipCode(response.Code)
            return
        end

        self._LastSyncServerBossRankTimes[levelType] = self._LastSyncServerBossRankTimes[levelType] or {}
        self._LastSyncServerBossRankTimes[levelType][bossId] = now
        self._Model:UpdateBossRankDataCache(levelType, bossId, response)
        if callback then
            callback(self._Model:GetBossRankDataCacheByTypeAndBossId(levelType, bossId))
        end
    end)
end

function XFubenBossSingleAgency:RequestChallengeRankData(callback, stageId)
    local now = XTime.GetServerNowTimestamp()

    stageId = stageId or 0
    if self._LastSyncServerChallengeRankTimes[stageId] and self._LastSyncServerChallengeRankTimes[stageId]
        + self._SyncServerSecond > now then
        local rankData = self._Model:GetChallengeRankDataCacheByStageId(stageId)
            
        if callback then
            if rankData then
                callback(rankData)
                return
            end
        else
            return
        end
    end

    local req = {
        StageId = stageId,
    }
    XNetwork.Call(METHOD_NAME.GetChallengeRankData, req, function(response)
        if response.Code ~= XCode.Success then
            XUiManager.TipCode(response.Code)
            return
        end

        self._LastSyncServerChallengeRankTimes[stageId] = now
        self._Model:UpdateChallengeRankDataCache(stageId, response)
        if callback then
            callback(self._Model:GetChallengeRankDataCacheByStageId(stageId))
        end
    end)
end

-- 保存战斗数据
function XFubenBossSingleAgency:RequestSaveScore(stagedId, cb)
    local req = {
        StageId = stagedId,
    }
    XNetwork.Call(METHOD_NAME.SaveScore, req, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        if cb then
            cb(res.Supply > 0)
        end
    end)
end

-- endregion

return XFubenBossSingleAgency
