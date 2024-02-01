---@class XFangKuaiActivity
---@field _SettleData XFangKuaiSettleData
---@field _StageDatas XFangKuaiStageData[]
local XFangKuaiActivity = XClass(nil, "XFangKuaiActivity")

function XFangKuaiActivity:Ctor()
    self._ActivityId = 0
    self._FinishedStageIds = {}
    self._StageMaxPointDict = {}
    self._StageDatas = {}
    self._SettleData = nil
end

function XFangKuaiActivity:NotifyFangKuaiData(data)
    self._ActivityId = data.ActivityId
    self._FinishedStageIds = data.FinishedStageIds
    self._StageMaxPointDict = data.StageMaxPointDict
    if data.StageDataDict then
        for chapterId, stageDate in pairs(data.StageDataDict) do
            self:UpdateStageData(chapterId, stageDate)
        end
    end
end

function XFangKuaiActivity:UpdateStageData(chapterId, data)
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

function XFangKuaiActivity:ClearStageData(chapterId)
    for id, stageData in pairs(self._StageDatas) do
        if not chapterId or chapterId == id then
            stageData:ResetData()
        end
    end
end

function XFangKuaiActivity:UpdateSettleData(data, stageId)
    if XTool.IsTableEmpty(data) then
        self._SettleData = nil
    else
        self._SettleData = {}
        self._SettleData.Point = data.Point
        self._SettleData.IsNewRecord = data.IsNewRecord
        self._SettleData.IsStageFinished = data.IsStageFinished
        self._SettleData.StageId = stageId or self._StageId
        self._SettleData.Round = data.Round
    end
end

---当前关卡是否已结束
function XFangKuaiActivity:IsStageFinished()
    return self._SettleData and self._SettleData.IsStageFinished
end

function XFangKuaiActivity:GetCurStageScore(chapterId)
    return self._StageDatas[chapterId] and self._StageDatas[chapterId].Point or 0
end

function XFangKuaiActivity:GetActivityId()
    return self._ActivityId
end

function XFangKuaiActivity:GetStageRecordScore(stageId)
    return self._StageMaxPointDict[stageId] or 0
end

function XFangKuaiActivity:GetCurStageId(chapterId)
    return self._StageDatas[chapterId] and self._StageDatas[chapterId].StageId or 0
end

function XFangKuaiActivity:GetAllBlocks(chapterId)
    return self._StageDatas[chapterId] and self._StageDatas[chapterId].Blocks or nil
end

function XFangKuaiActivity:GetLastBlockId(chapterId)
    return self._StageDatas[chapterId] and self._StageDatas[chapterId].LastBlockId or 0
end

function XFangKuaiActivity:GetCurRound(chapterId)
    return self._StageDatas[chapterId] and self._StageDatas[chapterId].Round or 0
end

function XFangKuaiActivity:GetExtraRound(chapterId)
    return self._StageDatas[chapterId] and self._StageDatas[chapterId].ExtraRound or 0
end

function XFangKuaiActivity:GetItemIds(chapterId)
    return self._StageDatas[chapterId] and self._StageDatas[chapterId].ItemIds or nil
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
---@field IsNewRecord boolean
---@field StageId number
---@field Round number