local XRedPointConditionSlotMachine = {}

function XRedPointConditionSlotMachine.Check()
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.SlotMachines) then
        return false
    end
    if XDataCenter.SlotMachineManager.CheckRedPoint() then
        return true
    end
    return false
end

return XRedPointConditionSlotMachine