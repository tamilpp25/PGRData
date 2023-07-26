--关卡汇报数据
---@class XGoldenMinerReportInfo
local XGoldenMinerReportInfo = XClass(nil, "XGoldenMinerReportInfo")

local Default = {
    _MapId = 0,
    _StageId = 0,
    _StageIndex = 0,
    _BeforeScore = 0,
    _TargetScore = 0,
    _LastTimeScore = 0,
    _MapScore = 0,
    _LastTime = 0,
    _GrabObjList = { },
    _GrabObjScoreDir = { },
}

function XGoldenMinerReportInfo:Ctor()
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
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

function XGoldenMinerReportInfo:SetGrabObjList(grabObjList)
    self._GrabObjList = grabObjList
end

function XGoldenMinerReportInfo:SetGrabObjScoreDir(grabObjScoreDir)
    self._GrabObjScoreDir = grabObjScoreDir
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

function XGoldenMinerReportInfo:GetMapScore()
    return self._MapScore
end

function XGoldenMinerReportInfo:GetLastTime()
    return self._LastTime
end

---@return XGoldenMinerEntityStone[]
function XGoldenMinerReportInfo:GetGrabObjList()
    return self._GrabObjList
end

function XGoldenMinerReportInfo:GetGrabObjScoreDir()
    return self._GrabObjScoreDir
end

function XGoldenMinerReportInfo:GetMapAddScore()
    return self._MapScore - self._BeforeScore
end

function XGoldenMinerReportInfo:IsWin()
    return self._TargetScore > 0 and self._MapScore + self._LastTimeScore >= self._TargetScore
end
--endregion

return XGoldenMinerReportInfo