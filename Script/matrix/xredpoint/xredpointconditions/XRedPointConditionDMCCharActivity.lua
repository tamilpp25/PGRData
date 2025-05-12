--- 3.5 鬼泣联动角色试玩活动总蓝点
local XRedPointConditionDMCCharActivity = {}

local ActivityIds = nil

function XRedPointConditionDMCCharActivity.Check()
    if ActivityIds == nil or XMain.IsEditorDebug then
        ActivityIds = {}
        ActivityIds[1] = XFubenNewCharConfig.GetClientConfigNumByKey('DMCActivityIds', 1)
        ActivityIds[2] = XFubenNewCharConfig.GetClientConfigNumByKey('DMCActivityIds', 2)
    end

    if not XTool.IsTableEmpty(ActivityIds) then
        if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_KOROMCHARACTIVITYTEACHINGRED, ActivityIds[1]) then
            return true
        end

        if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_NEWCHARACTIVITYTASK, ActivityIds[2]) then
            return true
        end

    end

    return false
end


return XRedPointConditionDMCCharActivity
