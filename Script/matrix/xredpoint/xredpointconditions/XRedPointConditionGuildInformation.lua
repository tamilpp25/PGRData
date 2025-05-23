
local XRedPointConditionGuildInformation = {}

local SubCondition = nil
function XRedPointConditionGuildInformation.GetSubConditions()
    SubCondition = SubCondition or {
        XRedPointConditions.Types.CONDITION_GUILD_APPLYLIST,
        XRedPointConditions.Types.CONDITION_GUILD_ACTIVEGIFT,
    }
    return SubCondition
end

function XRedPointConditionGuildInformation.Check()
    -- 礼包红点
    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_GUILD_ACTIVEGIFT) then
        return true
    end
    -- 招募红点
    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_GUILD_APPLYLIST) then
        return true
    end

    return false
end



return XRedPointConditionGuildInformation