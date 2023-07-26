local Events = nil
local SubCondition = nil

local XRedPointConditionKillZoneActivity = {}

function XRedPointConditionKillZoneActivity.GetSubConditions()
    SubCondition = SubCondition or {
        XRedPointConditions.Types.XRedPointConditionKillZoneStarReward,
    }
    return SubCondition
end

function XRedPointConditionKillZoneActivity.Check(chapterId)
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.KillZone) then
        return false
    end

    if not XDataCenter.KillZoneManager.IsOpen() then
        return false
    end

    if XDataCenter.KillZoneManager.IsAnyStarRewardCanGet() then
        return true
    end

    -- 入口只需要判断每日关卡是否点击过
    if not XDataCenter.KillZoneManager.GetCookieDailyStageClicked() then
        return true
    end

    return false
end

return XRedPointConditionKillZoneActivity