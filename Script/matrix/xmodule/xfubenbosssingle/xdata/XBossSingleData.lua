local XBossSingleStageHistory = require("XModule/XFubenBossSingle/XData/XBossSingleStageHistory")
local XBossSingleTrialStageInfo = require("XModule/XFubenBossSingle/XData/XBossSingleTrialStageInfo")

---@class XBossSingleData
local XBossSingleData = XClass(nil, "XBossSingleData")

function XBossSingleData:Ctor(data)
    self._IsEmpty = true
    self:SetData(data)
end

function XBossSingleData:SetData(data)
    if data then
        local historyList = data.HistoryList
        local trialStageInfoList = data.TrialStageInfoList
        local challengeHistoryList = data.ChallengeStageHistoryList

        self._IsEmpty = false
        self._ActivityNo = data.ActivityNo
        self._TotalScore = data.TotalScore
        self._MaxScore = data.MaxScore
        self._OldLevelType = data.OldLevelType
        self._LevelType = data.LevelType
        self._ChallengeCount = data.ChallengeCount
        self._RemainTime = data.RemainTime
        self._AutoFightCount = data.AutoFightCount
        self._CharacterPoints = data.CharacterPoints
        self._RewardIds = data.RewardIds
        self._RewardGroupId = data.RewardGroupId
        self._RankPlatform = data.RankPlatform
        self._BossList = data.BossList
        self._AfreshId = data.AfreshId or 0
        self._ChallengeSectionId = data.ChallengeSectionId or 0
        self._ChallengeFeatureGroupId = data.ChallengeFeatureGroupId or 0
        self._ChallengeLevelType = data.ChallengeLevelType
        self._ChallengeTotalScore = data.ChallengeTotalScore
        self._ChallengeDeleteRecordTime = data.ChallengeDeleteRecordTime or 0
        --- 结束时间是服务器刷新下发的，这里主动计算出结束的时间戳，方便倒计时计算
        self._EndTime = XTime.GetServerNowTimestamp() + data.RemainTime
        ---@type XBossSingleStageHistory[]
        self._HistoryList = {}
        ---@type XBossSingleStageHistory[]
        self._ChallengeStageHistoryList = {}
        ---@type table<number, XBossSingleTrialStageInfo>
        self._TrialStageInfoMap = {}

        if not XTool.IsTableEmpty(historyList) then
            for _, historyData in pairs(historyList) do
                table.insert(self._HistoryList, XBossSingleStageHistory.New(historyData))
            end
        end
        if not XTool.IsTableEmpty(trialStageInfoList) then
            for _, trialStageInfo in pairs(trialStageInfoList) do
                self._TrialStageInfoMap[trialStageInfo.StageId] = XBossSingleTrialStageInfo.New(trialStageInfo)
            end
        end
        if not XTool.IsTableEmpty(challengeHistoryList) then
            for _, historyData in pairs(challengeHistoryList) do
                table.insert(self._ChallengeStageHistoryList, XBossSingleStageHistory.New(historyData))
            end
        end
    end
end

function XBossSingleData:GetActivityNo()
    return self._ActivityNo
end

function XBossSingleData:GetTotalScore()
    return self._TotalScore
end

function XBossSingleData:GetMaxScore()
    return self._MaxScore
end

function XBossSingleData:GetOldLevelType()
    return self._OldLevelType
end

function XBossSingleData:GetLevelType()
    return self._LevelType
end

function XBossSingleData:SetChallengeCount(value)
    self._ChallengeCount = value
end

function XBossSingleData:GetChallengeCount()
    return self._ChallengeCount
end

function XBossSingleData:GetRemainTime()
    return self._RemainTime
end

function XBossSingleData:GetAutoFightCount()
    return self._AutoFightCount
end

function XBossSingleData:GetRewardGroupId()
    return self._RewardGroupId
end

function XBossSingleData:GetRankPlatform()
    return self._RankPlatform
end

function XBossSingleData:GetCharacterPointMap()
    return self._CharacterPoints
end

function XBossSingleData:AddRewardId(rewardId)
    if self._RewardIds then
        table.insert(self._RewardIds, rewardId)
    end
end

function XBossSingleData:GetRewardIdList()
    return self._RewardIds
end

function XBossSingleData:GetBossList()
    return self._BossList
end

---@return XBossSingleStageHistory[]
function XBossSingleData:GetHistoryList()
    return self._HistoryList
end

---@return table<number, XBossSingleTrialStageInfo>
function XBossSingleData:GetTrialStageInfoMap()
    return self._TrialStageInfoMap
end

function XBossSingleData:GetIsEmpty()
    return self._IsEmpty
end

function XBossSingleData:GetEndTime()
    return self._EndTime
end

function XBossSingleData:GetAfreshId()
    return self._AfreshId
end

function XBossSingleData:GetChallengeSectionId()
    return self._ChallengeSectionId
end

function XBossSingleData:GetChallengeFeatureGroupId()
    return self._ChallengeFeatureGroupId
end

---@return XBossSingleStageHistory[]
function XBossSingleData:GetChallengeStageHistoryList()
    return self._ChallengeStageHistoryList
end

function XBossSingleData:GetChallengeLevelType()
    return self._ChallengeLevelType
end

function XBossSingleData:GetChallengeTotalScore()
    return self._ChallengeTotalScore
end

function XBossSingleData:GetChallengeDeleteRecordTime()
   return self._ChallengeDeleteRecordTime 
end

return XBossSingleData
