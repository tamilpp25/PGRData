local XRedPointConditionSlotMachine = {}

function XRedPointConditionSlotMachine.Check(id)
    if not XTool.IsNumberValid(id) then
        return false
    end
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.SlotMachines) then
        return false
    end
    if XDataCenter.SlotMachineManager.CheckRedPoint(id) then
        return true
    end
    return false
end

return XRedPointConditionSlotMachine