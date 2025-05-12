local XRedPointBagOrganizeActivityAny = {}

local SubCondition = nil

function XRedPointBagOrganizeActivityAny.GetSubConditions()
    SubCondition = SubCondition or {
        XRedPointConditions.Types.CONDITION_BAGORGANIZE_NEWCHAPTER,
        XRedPointConditions.Types.CONDITION_BAGORGANIZE_TASK,
    }

    return SubCondition
end


function XRedPointBagOrganizeActivityAny:Check()

    if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.BagOrganizeActivity, false, true) then
        local conditions = XRedPointBagOrganizeActivityAny.GetSubConditions()

        if not XTool.IsTableEmpty(conditions) then
            if XRedPointManager.CheckConditions(conditions) then
                return true
            end
        end
    end
    
    return false
end


return XRedPointBagOrganizeActivityAny
