--关卡汇报数据
---@class XGoldenMinerReportInfo
local XGoldenMinerReportInfo = XClass(nil, "XGoldenMinerReportInfo")

function XGoldenMinerReportInfo:Ctor()
    self._MapId = 0
    self._StageId = 0
    self._StageIndex = 0
    self._BeforeScore = 0
    self._TargetScore = 0
    self._MapScore = 0
    --- 过关剩余时间
    self._LastTime = 0
    --- 剩余时间换算的分数
    self._LastTimeScore = 0
    --- 掘金者雷达剩余时间换算的分数
    self._PartnerRadarScore = 0
    ---@type table<number, XGoldenMinerGrabReportInfo> key = stoneType
    self._ReportGrabStoneDataDir = {}
    self._FinishHideTaskCount = 0
    self._SlotScoreHandleCountMap = {}
end

--region Setter
function XGoldenMinerReportInfo:SetMapId(mapId)
    self._MapId = mapId
end

function XGoldenMinerReportInfo:SetStageId(stageId)
    self._StageId = stageId
end

function XGoldenMinerReportInfo:SetStageIndex(stageIndex)
    self._StageIndex = stageIndex
end

function XGoldenMinerReportInfo:SetBeforeScore(beforeScore)
    self._BeforeScore = beforeScore
end

function XGoldenMinerReportInfo:SetTargetScore(targetScore)
    self._TargetScore = targetScore
end

function XGoldenMinerReportInfo:SetLastTimeScore(lastTimeScore)
    self._LastTimeScore = lastTimeScore
end

function XGoldenMinerReportInfo:SetMapScore(mapScore)
    self._MapScore = mapScore
end

function XGoldenMinerReportInfo:SetLastTime(lastTime)
    self._LastTime = lastTime
end

function XGoldenMinerReportInfo:SetPartnerRadarScore(value)
    self._PartnerRadarScore = value
end

function XGoldenMinerReportInfo:SetReportGrabStoneDataDir(data)
    self._ReportGrabStoneDataDir = data
end

function XGoldenMinerReportInfo:SetFinishHideTaskCount(finishHideTaskCount)
    self._FinishHideTaskCount = finishHideTaskCount
end

function XGoldenMinerReportInfo:SetSlotScoreHandleCountMap(mapData)
    self._SlotScoreHandleCountMap = mapData
end
--endregion

--region Getter
function XGoldenMinerReportInfo:GetMapId()
    return self._MapId
end

function XGoldenMinerReportInfo:GetStageId()
    return self._StageId
end

function XGoldenMinerReportInfo:GetStageIndex()
    return self._StageIndex
end

function XGoldenMinerReportInfo:GetBeforeScore()
    return self._BeforeScore
end

function XGoldenMinerReportInfo:GetTargetScore()
    return self._TargetScore
end

function XGoldenMinerReportInfo:GetLastTimeScore()
    return self._LastTimeScore
end

function XGoldenMinerReportInfo:GetPartnerRadarScore()
    return self._PartnerRadarScore
end

function XGoldenMinerReportInfo:GetMapScore()
    return self._MapScore
end

function XGoldenMinerReportInfo:GetLastTime()
    return self._LastTime
end

function XGoldenMinerReportInfo:GetReportGrabStoneDataDir()
    return self._ReportGrabStoneDataDir
end

function XGoldenMinerReportInfo:GetMapAddScore()
    return self._MapScore - self._BeforeScore
end

function XGoldenMinerReportInfo:GetFinishHideTaskCount()
    return self._FinishHideTaskCount
end

function XGoldenMinerReportInfo:IsWin()
    return self._TargetScore > 0 and self._MapScore >= self._TargetScore
end

function XGoldenMinerReportInfo:GetSlotScoreHandleCountMap()
    return self._SlotScoreHandleCountMap
end
--endregion

return XGoldenMinerReportInfo