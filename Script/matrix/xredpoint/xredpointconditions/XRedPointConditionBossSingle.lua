----------------------------------------------------------------
--超难关：有可挑战的关卡

local XRedPointConditionBossSingle = {}
local Events = nil
local Conditions = nil
function XRedPointConditionBossSingle.GetSubEvents()
    Events = Events or
    {
    }
    return Events
end

function XRedPointConditionBossSingle.GetSubConditions()
    Conditions = Conditions or { 
        XRedPointConditions.Types.CONDITION_ACTIVITY_BOSS_SINGLE_NEW 
    }
    return Conditions
end

--有关卡还没打， 而且开放了
function XRedPointConditionBossSingle.Check()
    if XDataCenter.FubenActivityBossSingleManager.CheckActivityRedPoint() then
        return true
    end
    return XRedPointActivityBossSingleStoryNew.Check()
end

return XRedPointConditionBossSingle