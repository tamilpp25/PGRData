local type = type

--大逃杀关卡通关结果
---@class XEscapeStageResult
local XEscapeStageResult = XClass(nil, "XEscapeStageResult")

local Default = {
    _StageId = 0,
    _CostTime = 0,  --通关用时（单位：秒）
    _HitTimes = 0,       --受击次数
    _TrapedTimes = 0,    --陷阱受击次数
}

function XEscapeStageResult:Ctor()
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
end

function XEscapeStageResult:UpdateData(data)
    self._StageId = data.StageId
    self._CostTime = data.CostTime
    self._HitTimes = data.HitTimes
    self._TrapedTimes = data.TrapedTimes
end

function XEscapeStageResult:GetStageId()
    return self._StageId
end

function XEscapeStageResult:GetCostTime()
    return self._CostTime or 0
end

function XEscapeStageResult:GetHit()
    return self._HitTimes or 0
end

function XEscapeStageResult:GetTrapHit()
    return self._TrapedTimes or 0
end

return XEscapeStageResult