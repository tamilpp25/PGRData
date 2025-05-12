
local XRedPointTwoSideTowerNewChapter= {}
local Events = nil

function XRedPointTwoSideTowerNewChapter.GetSubEvents()
    Events = Events or {
    }
    return Events
end

function XRedPointTwoSideTowerNewChapter.Check()
    ---@type XTwoSideTowerAgency
    local twoSideTowerAgency = XMVCA:GetAgency(ModuleId.XTwoSideTower)
    return twoSideTowerAgency:CheckChapterOpenRed()
end

return XRedPointTwoSideTowerNewChapter