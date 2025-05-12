local XRedPointGame2048Main = {}

local SubCondition = nil

function XRedPointGame2048Main.GetSubConditions()
    SubCondition = SubCondition or {
        XRedPointConditions.Types.CONDITION_GAME2048_NEWCHAPTER,
        XRedPointConditions.Types.CONDITION_GAME2048_STORE,
    }

    return SubCondition
end


function XRedPointGame2048Main:Check()
    if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Game2048, false, true) then
        local conditions = XRedPointGame2048Main.GetSubConditions()

        if not XTool.IsTableEmpty(conditions) then
            if XRedPointManager.CheckConditions(conditions) then
                return true
            end
        end
    end

    return false
end


return XRedPointGame2048Main
