XRedPointConditionNieRRed = {}
--local Events = nil
local SubConditions = nil
-- function XRedPointConditionNieRRed.GetSubEvents()
--     Events = Events or {
--         XRedPointEventElement.New(XEventId.EVENT_TASK_SYNC)
--     }
--     return Events
-- end
function XRedPointConditionNieRRed.GetSubConditions()
    SubConditions = SubConditions or
    {
        XRedPointConditions.Types.CONDITION_NIER_TASK_RED,
        XRedPointConditions.Types.CONDITION_NIER_POD_RED,
        XRedPointConditions.Types.CONDITION_NIER_REPEAT_RED,
        XRedPointConditions.Types.CONDITION_NIER_CHARACTER_RED,
    }
    return SubConditions
end

function XRedPointConditionNieRRed.Check()
    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_NIER_POD_RED) then
        return true
    end

    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_NIER_REPEAT_RED) then
        return true
    end
    
    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_NIER_TASK_RED, -1) then
        return true
    end
    
    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_NIER_CHARACTER_RED,  {CharacterId = -1, IsInfor = true, IsTeach = true}) then
        return true
    end
    
    return false
end

return XRedPointConditionNieRRed