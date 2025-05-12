--- 新矿区总蓝点
local XRedPointScoreTowerMain = {}

local SubCondition = nil

function XRedPointScoreTowerMain.GetSubConditions()
    SubCondition = SubCondition or {
        XRedPointConditions.Types.CONDITION_SCORETOWER_NEWCHAPTER,
        XRedPointConditions.Types.CONDITION_SCORETOWER_RANK,
        XRedPointConditions.Types.CONDITION_SCORETOWER_TASK,
    }

    return SubCondition
end


function XRedPointScoreTowerMain.Check()
    if XMVCA.XScoreTower:GetIsOpen(true) then
        local conditions = XRedPointScoreTowerMain.GetSubConditions()

        if not XTool.IsTableEmpty(conditions) then
            if XRedPointManager.CheckConditions(conditions, true) then
                return true
            end
        end
    end

    return false
end



return XRedPointScoreTowerMain