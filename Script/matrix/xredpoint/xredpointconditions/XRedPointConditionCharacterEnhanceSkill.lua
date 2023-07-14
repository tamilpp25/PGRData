
----------------------------------------------------------------
--角色技能红点检测
local XRedPointConditionCharacterEnhanceSkill = {}
local Events = nil
function XRedPointConditionCharacterEnhanceSkill.GetSubEvents()--TODO需要写具体逻辑
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_CHARACTER_LEVEL_UP),
        XRedPointEventElement.New(XEventId.EVENT_CHARACTER_ENHANCESKILL_UP),
        XRedPointEventElement.New(XEventId.EVENT_CHARACTER_ENHANCESKILL_UNLOCK),
    }
    return Events
end

function XRedPointConditionCharacterEnhanceSkill.Check(characterId)
    if not characterId then
        return false
    end

    if not XFunctionManager.JudgeOpen(XFunctionManager.FunctionName.CharacterEnhanceSkill) then
        return false
    end
    
    return XDataCenter.CharacterManager.CheckCharacterShowRed(characterId)
end

return XRedPointConditionCharacterEnhanceSkill