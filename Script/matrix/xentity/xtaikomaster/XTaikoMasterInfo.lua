---@class XTaikoMasterInfo@音游基础信息
local XTaikoMasterInfo = XClass(nil, "XTaikoMasterInfo")

function XTaikoMasterInfo:Ctor()
    self._ActivityId = XTaikoMasterConfigs.GetDefaultActivityId()
    ---@type {StageId:number,MaxScore:number,MaxAccuracy:number,MaxCombo:number}[]
    self._StageDataList = {}
    self._AppearScale = 0
    self._JudgeScale = 0
    self._RankData = {}
end

function XTaikoMasterInfo:GetActivityId()
    return self._ActivityId
end

function XTaikoMasterInfo:SetData(data)
    if not data then
        return
    end
    if XTool.IsNumberValid(data.ActivityId) then
        self._ActivityId = data.ActivityId
    end
    self._StageDataList = {}
    for i = 1, #data.StageDataList do
        local stage = data.StageDataList[i]
        self._StageDataList[stage.StageId] = stage
    end
    local setting = data.Setting
    if setting then
        self:SetSetting(setting.AppearOffset, setting.JudgeOffset)
    end
end

function XTaikoMasterInfo:SetSetting(appearScale, judgeScale)
    self._AppearScale = appearScale
    self._JudgeScale = judgeScale
end

function XTaikoMasterInfo:GetSettingAppearScale()
    return self._AppearScale
end

function XTaikoMasterInfo:GetSettingJudgeScale()
    return self._JudgeScale
end

---@return {Ranking:number,TotalCount:number,RankPlayerInfoList:table}
function XTaikoMasterInfo:GetRankData(songId)
    return self._RankData[songId] or {}
end

function XTaikoMasterInfo:SetRankData(songId, rankData)
    if rankData.RankPlayerInfoList then
        for rank = 1, #rankData.RankPlayerInfoList do
            local playerRank = rankData.RankPlayerInfoList[rank]
            -- 服务端没将排行放进结构，index隐含排行
            if not playerRank.Rank then
                playerRank.Rank = rank
            end
        end
    end
    self._RankData[songId] = rankData
    XEventManager.DispatchEvent(XEventId.EVENT_TAIKO_MASTER_RANK_UPDATE, songId)
end

function XTaikoMasterInfo:GetStageData(stageId)
    return self._StageDataList[stageId]
end

function XTaikoMasterInfo:GetMyScore(stageId)
    local stage = self:GetStageData(stageId)
    local score = stage and stage.MaxScore
    return score or 0, score and true or false
end

function XTaikoMasterInfo:GetMyAccuracy(stageId)
    local stage = self:GetStageData(stageId)
    return stage and stage.MaxAccuracy or 0
end

function XTaikoMasterInfo:GetMyCombo(stageId)
    local stage = self:GetStageData(stageId)
    return stage and stage.MaxCombo or 0
end

function XTaikoMasterInfo:GetMyPerfect(stageId)
    local stage = self:GetStageData(stageId)
    return stage and stage.MaxPerfect or 0
end

function XTaikoMasterInfo:GetMyAccuracyUnderMaxScore(stageId)
    local stage = self:GetStageData(stageId)
    return stage and stage.AccuracyUnderMaxScore or 0
end

function XTaikoMasterInfo:GetMyComboUnderMaxScore(stageId)
    local stage = self:GetStageData(stageId)
    return stage and stage.ComboUnderMaxScore or 0
end

function XTaikoMasterInfo:HandleWinData(stageId, winData)
    if not winData then
        return
    end
    local stage = self._StageDataList[stageId]
    if not stage then
        stage = {}
        self._StageDataList[stageId] = stage
    end
    local maxScore = stage.MaxScore or 0
    stage.MaxAccuracy = math.max((stage.MaxAccuracy or 0), winData.Accuracy)
    stage.MaxScore = math.max((maxScore), winData.Score)
    stage.MaxCombo = math.max((stage.MaxCombo or 0), winData.Combo)
    stage.MaxPerfect = math.max((stage.MaxPerfect or 0), winData.Perfect)
    if winData.Score >= maxScore then
        stage.AccuracyUnderMaxScore = winData.Accuracy
        stage.ComboUnderMaxScore = winData.Combo
    end
end

return XTaikoMasterInfo
