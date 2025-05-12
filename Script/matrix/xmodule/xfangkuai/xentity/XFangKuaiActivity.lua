---@class XFangKuaiActivity
---@field _SettleData XFangKuaiSettleData
---@field _StageDatas XFangKuaiStageData[]
local XFangKuaiActivity = XClass(nil, "XFangKuaiActivity")

function XFangKuaiActivity:Ctor()
    self._ActivityId = 0
    self._FinishedStageIds = {}
    self._StageHistroyDict = {}
    self._StageDatas = {}
    self._SettleData = nil
end

function XFangKuaiActivity:NotifyFangKuaiData(data)
    self._ActivityId = data.ActivityId
    self._FinishedStageIds = data.FinishedStageIds
    self._StageHistroyDict = data.StageHistroyDict
    if data.StageDataDict then
        for chapterId, stageDate in pairs(data.StageDataDict) do
            self:UpdateRecordStageData(chapterId, stageDate)
        end
    end
end

function XFangKuaiActivity:UpdateRecordStageData(chapterId, data)
    if not data then
        return
    end
    local stage = self._StageDatas[chapterId]
    if not stage then
        stage = require("XModule/XFangKuai/XEntity/XFangKuaiStageData").New()
        self._StageDatas[chapterId] = stage
    end
    stage:UpdateStageData(data)
end

function XFangKuaiActivity:UpdateStageData(chapterId, data)
    self._StageDatas[chapterId] = data
end

function XFangKuaiActivity:ClearStageData(chapterId)
    if chapterId then
        self._StageDatas[chapterId] = nil
    else
        self._StageDatas = {}
    end
end

function XFangKuaiActivity:UpdateSettleData(data, stageId)
    if XTool.IsTableEmpty(data) then
        self._SettleData = nil
    else
        self._SettleData = {}
        self._SettleData.Point = data.Point
        self._SettleData.IsNewScoreRecord = data.IsNewScoreRecord
        self._SettleData.IsNewRoundRecord = data.IsNewRoundRecord
        self._SettleData.IsStageFinished = data.IsStageFinished
        self._SettleData.StageId = stageId or self._StageId
        self._SettleData.Round = data.Round
    end
end

function XFangKuaiActivity:GetRecordStageScore(chapterId)
    return self._StageDatas[chapterId] and self._StageDatas[chapterId].Point or 0
end

function XFangKuaiActivity:GetActivityId()
    return self._ActivityId
end

function XFangKuaiActivity:GetMaxScore(stageId)
    return self._StageHistroyDict[stageId] and self._StageHistroyDict[stageId].MaxScore or 0
end

function XFangKuaiActivity:GetTotalRound(stageId)
    return self._StageHistroyDict[stageId] and self._StageHistroyDict[stageId].TotalRound or 0
end

function XFangKuaiActivity:GetMaxRound(stageId)
    return self._StageHistroyDict[stageId] and self._StageHistroyDict[stageId].MaxRound or 0
end

function XFangKuaiActivity:GetStageData(chapterId)
    return self._StageDatas[chapterId]
end

function XFangKuaiActivity:ClearAllBlock(chapterId)
    local stageData = self:GetStageData(chapterId)
    if stageData then
        stageData:ClearBlock()
    end
end

function XFangKuaiActivity:GetSettleData()
    return self._SettleData
end

---关卡是否通关过
function XFangKuaiActivity:IsStagePass(stageId)
    return table.indexof(self._FinishedStageIds, stageId)
end

return XFangKuaiActivity

---@class XFangKuaiSettleData
---@field IsStageFinished boolean
---@field Point number
---@field IsNewScoreRecord boolean 是否更高的分数记录
---@field IsNewRoundRecord boolean 是否更高的回合数记录
---@field StageId number
---@field Round number