
----------------------------------------------------------------
--角色晋升红点检测
local XRedPointConditionCharacterGrade = {}
local Events = nil

function XRedPointConditionCharacterGrade.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_CHARACTER_LEVEL_UP),
        XRedPointEventElement.New(XEventId.EVENT_CHARACTER_GRADE),
        XRedPointEventElement.New(XEventId.EVENT_CHARACTER_GRADE_PART),
        XRedPointEventElement.New(XEventId.EVENT_ITEM_BUYASSET, {XDataCenter.ItemManager.ItemId.Coin})
    }
    return Events
end

function XRedPointConditionCharacterGrade.Check(characterId)
    if not characterId then
        return false
    end

    ---@type XCharacterAgency
    local ag = XMVCA:GetAgency(ModuleId.XCharacter)

    if not XFunctionManager.JudgeOpen(XFunctionManager.FunctionName.CharacterGrade) then
        return false
    end

    return ag:CanPromoteGrade(characterId)
end

return XRedPointConditionCharacterGrade