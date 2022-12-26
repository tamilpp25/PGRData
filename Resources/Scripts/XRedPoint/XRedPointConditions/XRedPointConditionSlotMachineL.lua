
local XRedPointConditionSlotMachineL = {}

function XRedPointConditionSlotMachineL.Check()
    if XDataCenter.SlotMachineManager.CheckRedPointL() then
        return true
    end
    return false
end

return XRedPointConditionSlotMachineL