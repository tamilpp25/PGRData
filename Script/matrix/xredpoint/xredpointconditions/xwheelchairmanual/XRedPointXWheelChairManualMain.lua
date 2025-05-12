--- 总蓝点，用于手册入口
local XRedPointXWheelChairManualMain = {}

local SubCondition = nil

function XRedPointXWheelChairManualMain.GetSubConditions()
    SubCondition = SubCondition or {
        XRedPointConditions.Types.CONDITION_WHEELCHAIRMANUAL_PLANREWARD,
        XRedPointConditions.Types.CONDITION_WHEELCHAIRMANUAL_PLANTASK,
        XRedPointConditions.Types.CONDITION_WHEELCHAIRMANUAL_BP,
        XRedPointConditions.Types.CONDITION_WHEELCHAIRMANUAL_LOTTO,
        XRedPointConditions.Types.CONDITION_WHEELCHAIRMANUAL_GIFT,
        XRedPointConditions.Types.CONDITION_WHEELCHAIRMANUAL_TEACHING,
        XRedPointConditions.Types.CONDITION_WHEELCHAIRMANUAL_GUIDE,
    }

    return SubCondition
end

function XRedPointXWheelChairManualMain:Check()
    if not XMVCA.XWheelchairManual:GetIsOpen(nil, true) then
        return false
    end

    local conditions = XRedPointXWheelChairManualMain.GetSubConditions()

    if not XTool.IsTableEmpty(conditions) then
        if XRedPointManager.CheckConditions(conditions) then
            return true
        end
    end
    return false
end

return XRedPointXWheelChairManualMain