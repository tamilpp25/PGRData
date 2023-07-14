
local XRedPointConditionSlotMachine = {}

function XRedPointConditionSlotMachine.Check()
    if XDataCenter.SlotMachineManager.CheckRedPoint() then
        return true
    end
    return false
end

return XRedPointConditionSlotMachine