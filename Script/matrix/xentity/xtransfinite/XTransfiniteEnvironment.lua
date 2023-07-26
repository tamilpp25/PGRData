---@class XTransfiniteEnvironment
local XTransfiniteEnvironment = XClass(nil, "XTransfiniteEnvironment")

function XTransfiniteEnvironment:Ctor()
    ---@type XTransfiniteEnvironmentData[]
    self._Data = false
end

---@param stageGroup XTransfiniteStageGroup
function XTransfiniteEnvironment:SetStageGroup(stageGroup)
    self._Data = {}
    local eventList = stageGroup:GetFightEvent()
    for i = 1, #eventList do
        local event = eventList[i]
        ---@class XTransfiniteEnvironmentData
        local dataEvent = {
            Name = event:GetName(),
            Desc = event:GetDesc(),
            Icon = event:GetIcon(),
            Index = i,
        }
        self._Data[i] = dataEvent
    end
end

function XTransfiniteEnvironment:GetData()
    return self._Data
end

return XTransfiniteEnvironment
