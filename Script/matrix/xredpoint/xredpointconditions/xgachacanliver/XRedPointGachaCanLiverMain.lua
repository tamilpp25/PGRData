local XRedPointGachaCanLiverMain = {}

local SubCondition = nil

function XRedPointGachaCanLiverMain.GetSubConditions()
    SubCondition = SubCondition or {
        XRedPointConditions.Types.CONDITION_GACHACANLIVER_SHOP,
        XRedPointConditions.Types.CONDITION_GACHACANLIVER_TASK,
        XRedPointConditions.Types.CONDITION_GACHACANLIVER_TIMELIMITDRAW,
        XRedPointConditions.Types.CONDITION_GACHACANLIVER_DRAW,
    }

    return SubCondition
end

function XRedPointGachaCanLiverMain:Check()
    if not XMVCA.XGachaCanLiver:GetIsOpen() then
        return false
    end

    local conditions = XRedPointGachaCanLiverMain.GetSubConditions()

    if not XTool.IsTableEmpty(conditions) then
        if XRedPointManager.CheckConditions(conditions) then
            return true
        end
    end

    return false
end

return XRedPointGachaCanLiverMain