local XBossSingleData = require("XModule/XFubenBossSingle/XData/XBossSingleData")
local XBossSingleSelfRankInfo = require("XModule/XFubenBossSingle/XData/XBossSingleSelfRankInfo")
local XBossSingleTrialStageMap = require("XModule/XFubenBossSingle/XData/XBossSingleTrialStageMap")

---@class XBossSingle
local XBossSingle = XClass(nil, "XBossSingle")

function XBossSingle:Ctor()
    ---@type XBossSingleData
    self._BossSingleData = nil
    ---@type XBossSingleSelfRankInfo
    self._SelfRankInfo = nil
    self._TrialStageMap = 0
    ---@type table<number, number[]>
    self._ChooseAbleBossListMap = nil

    self._EnterBossId = 0
    self._EnterBossLevel = 0
    self._IsNeedReset = false
    self._IsFirstUnlockChallenge = true
end

-- region XBossSingleData

function XBossSingle:SetBossSingleData(data)
    if not self._BossSingleData then
        self._BossSingleData = XBossSingleData.New(data)
        self._IsNeedReset = false
        self._IsFirstUnlockChallenge = self._BossSingleData:GetChallengeLevelType() == 0
    else
        local oldActivityId = self._BossSingleData:GetActivityNo()
        local oldChallengeType = self._BossSingleData:GetChallengeLevelType()
        local newActivityId = data.ActivityNo

        self._BossSingleData:SetData(data)
        self._IsNeedReset = oldActivityId and newActivityId and oldActivityId ~= newActivityId
        self._IsFirstUnlockChallenge = oldChallengeType == 0 and oldChallengeType ~= self._BossSingleData:GetChallengeLevelType()

        if self._IsNeedReset then
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_ACTIVITY_ON_RESET, XEnumConst.FuBen.StageType.BossSingle)
        end
    end
end

function XBossSingle:IsBossSingleEmpty()
    return not self._BossSingleData or self._BossSingleData:GetIsEmpty()
end

function XBossSingle:GetBossSingleActivityNo()
    if self:IsBossSingleEmpty() then
        return 0
    else
        return self._BossSingleData:GetActivityNo()
    end
end

function XBossSingle:GetBossSingleTotalScore()
    if self:IsBossSingleEmpty() then
        return 0
    else
        return self._BossSingleData:GetTotalScore()
    end
end

function XBossSingle:GetBossSingleMaxScore()
    if self:IsBossSingleEmpty() then
        return 0
    else
        return self._BossSingleData:GetMaxScore()
    end
end

function XBossSingle:GetBossSingleOldLevelType()
    if self:IsBossSingleEmpty() then
        return XEnumConst.BossSingle.LevelType.ChooseAble
    else
        return self._BossSingleData:GetOldLevelType()
    end
end

function XBossSingle:GetBossSingleLevelType()
    if self:IsBossSingleEmpty() then
        return XEnumConst.BossSingle.LevelType.ChooseAble
    else
        return self._BossSingleData:GetLevelType()
    end
end

function XBossSingle:SetChallengeCount(value)
    if not self:IsBossSingleEmpty() then
        return self._BossSingleData:SetChallengeCount(value)
    end
end

function XBossSingle:GetBossSingleChallengeCount()
    if self:IsBossSingleEmpty() then
        return 0
    else
        return self._BossSingleData:GetChallengeCount()
    end
end

function XBossSingle:GetBossSingleRemainTime()
    if self:IsBossSingleEmpty() then
        return 0
    else
        return self._BossSingleData:GetRemainTime()
    end
end

function XBossSingle:GetBossSingleAutoFightCount()
    if self:IsBossSingleEmpty() then
        return 0
    else
        return self._BossSingleData:GetAutoFightCount()
    end
end

function XBossSingle:GetBossSingleRewardGroupId()
    if self:IsBossSingleEmpty() then
        return 0
    else
        return self._BossSingleData:GetRewardGroupId()
    end
end

function XBossSingle:GetBossSingleRankPlatform()
    if self:IsBossSingleEmpty() then
        return XEnumConst.BossSingle.Platform.Android
    else
        return self._BossSingleData:GetRankPlatform()
    end
end

function XBossSingle:GetBossSingleCharacterPointMap()
    if self:IsBossSingleEmpty() then
        return {}
    else
        return self._BossSingleData:GetCharacterPointMap()
    end
end

function XBossSingle:GetBossSingleRewardIdList()
    if self:IsBossSingleEmpty() then
        return {}
    else
        return self._BossSingleData:GetRewardIdList()
    end
end

function XBossSingle:AddBossSingleRewardId(rewardId)
    if not self:IsBossSingleEmpty() then
        self._BossSingleData:AddRewardId(rewardId)
    end
end

function XBossSingle:GetBossSingleBossList()
    if self:IsBossSingleEmpty() then
        return {}
    else
        return self._BossSingleData:GetBossList()
    end
end

function XBossSingle:GetBossSingleBossIdByIndex(index)
    if self:IsBossSingleEmpty() then
        return 0
    else
        local bossList = self:GetBossSingleBossList()

        return bossList[index]
    end
end

function XBossSingle:GetBossIndexByBossId(bossId)
    if self:IsBossSingleEmpty() then
        return 1
    else
        local bossList = self:GetBossSingleBossList()

        for i, id in pairs(bossList) do
            if id == bossId then
                return i
            end
        end

        return 1
    end
end

function XBossSingle:GetBossSingleHistoryList()
    if self:IsBossSingleEmpty() then
        return {}
    else
        return self._BossSingleData:GetHistoryList()
    end
end

---@return table<number, XBossSingleTrialStageInfo>
function XBossSingle:GetBossSingleTrialStageInfoMap()
    if self:IsBossSingleEmpty() then
        return {}
    else
        return self._BossSingleData:GetTrialStageInfoMap()
    end
end

---@return XBossSingleTrialStageInfo
function XBossSingle:GetBossSingleTrialStageInfoByStageId(stageId)
    local infoMap = self:GetBossSingleTrialStageInfoMap()

    return infoMap[stageId]
end

function XBossSingle:GetBossSingleEndTime()
    if self:IsBossSingleEmpty() then
        return 0
    else
        return self._BossSingleData:GetEndTime()
    end
end

function XBossSingle:GetBossSingleAfreshId()
    if self:IsBossSingleEmpty() then
        return 0
    else
        return self._BossSingleData:GetAfreshId()
    end
end

function XBossSingle:IsCurrentAfreshId(afreshId)
    return self:GetBossSingleAfreshId() == afreshId
end

function XBossSingle:IsCurrentConfig(config)
    if not config.AfreshId then
        return false
    end

    return self:IsCurrentAfreshId(config.AfreshId)
end

function XBossSingle:IsNewVersion()
    return self:GetBossSingleAfreshId() == 1
end

function XBossSingle:GetBossSingleChallengeFeatureGroupId()
    if self:IsBossSingleEmpty() then
        return 0
    else
        return self._BossSingleData:GetChallengeFeatureGroupId()
    end
end

function XBossSingle:GetBossSingleChallengeSectionId()
    if self:IsBossSingleEmpty() then
        return 0
    else
        return self._BossSingleData:GetChallengeSectionId()
    end
end

function XBossSingle:GetBossSingleChallengeLevelType()
    if self:IsBossSingleEmpty() then
        return XEnumConst.BossSingle.LevelType.ChooseAble
    else
        return self._BossSingleData:GetChallengeLevelType()
    end
end

---@return XBossSingleStageHistory[]
function XBossSingle:GetBossSingleChallengeHistoryList()
    if self:IsBossSingleEmpty() then
        return {}
    else
        return self._BossSingleData:GetChallengeStageHistoryList()
    end
end

function XBossSingle:GetBossSingleChallengeTotalScore()
    if self:IsBossSingleEmpty() then
        return 0
    else
        return self._BossSingleData:GetChallengeTotalScore()
    end
end

function XBossSingle:GetBossSingleChallengeDeleteRecordTime()
    if self:IsBossSingleEmpty() then
        return 0
    else
        return self._BossSingleData:GetChallengeDeleteRecordTime()
    end
end

function XBossSingle:FindChallengeStageHistoryByStageId(stageId)
    local historyList = self:GetBossSingleChallengeHistoryList()

    for _, history in pairs(historyList) do
        if history:GetStageId() == stageId then
            return history
        end
    end

    return nil
end

function XBossSingle:CheckHasChallengeData()
    local levelType = self:GetBossSingleChallengeLevelType()
    local sectionId = self:GetBossSingleChallengeSectionId()
    local featureGroupId = self:GetBossSingleChallengeFeatureGroupId()

    return XTool.IsNumberValid(levelType) and XTool.IsNumberValid(sectionId) and XTool.IsNumberValid(featureGroupId)
end

-- endregion

-- region XBossSingleSelfRankInfo

function XBossSingle:SetSelfRankInfo(info)
    if not self._SelfRankInfo then
        self._SelfRankInfo = XBossSingleSelfRankInfo.New(info)
    else
        self._SelfRankInfo:SetData(info)
    end
end

function XBossSingle:IsSelfRankInfoEmpty()
    return not self._SelfRankInfo or self._SelfRankInfo:GetIsEmpty()
end

function XBossSingle:SetSelfRankInfoRank(value)
    if not self:IsSelfRankInfoEmpty() then
        self._SelfRankInfo:SetRank(value)
    end
end

function XBossSingle:GetSelfRankInfoRank()
    if self:IsSelfRankInfoEmpty() then
        return 0
    else
        return self._SelfRankInfo:GetRank()
    end
end

function XBossSingle:SetSelfRankInfoTotalRank(value)
    if not self:IsSelfRankInfoEmpty() then
        self._SelfRankInfo:SetTotalRank(value)
    end
end

function XBossSingle:GetSelfRankInfoTotalRank()
    if self:IsSelfRankInfoEmpty() then
        return 0
    else
        return self._SelfRankInfo:GetTotalRank()
    end
end

-- endregion

-- region ChooseAbleBossListMap

function XBossSingle:SetChooseAbleBossListMap(value)
    self._ChooseAbleBossListMap = value
end

---@return number[], number[]
function XBossSingle:GetAllChooseAbleBossList()
    if not self._ChooseAbleBossListMap then
        return nil, nil
    else
        local highType = XMVCA.XFubenBossSingle:GetLevelTypeByGradeType(XEnumConst.BossSingle.LevelType.High)
        local extremeType = XMVCA.XFubenBossSingle:GetLevelTypeByGradeType(XEnumConst.BossSingle.LevelType.Extreme)

        return self._ChooseAbleBossListMap[highType], self._ChooseAbleBossListMap[extremeType]
    end
end

-- endregion

-- region EnterBossInfo

function XBossSingle:SetEnterBossId(value)
    self._EnterBossId = value or 0
end

function XBossSingle:GetEnterBossId()
    return self._EnterBossId
end

function XBossSingle:SetEnterBossLevel(value)
    self._EnterBossLevel = value or 0
end

function XBossSingle:GetEnterBossLevel()
    return self._EnterBossLevel
end

-- endregion

function XBossSingle:GetIsNeedReset()
    return self._IsNeedReset
end

function XBossSingle:SetIsNeedReset(value)
    self._IsNeedReset = value
end

function XBossSingle:GetIsFirstUnlockChallenge()
    return self._IsFirstUnlockChallenge
end

function XBossSingle:UnlockChallenge()
    self._IsFirstUnlockChallenge = false
end

return XBossSingle
