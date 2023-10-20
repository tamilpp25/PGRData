----------------------------------------------------------------
--单个邮件检测
local XRedPointConditionFavorability = {}

local SubCondition = nil
function XRedPointConditionFavorability.GetSubConditions()
    SubCondition = SubCondition or {
        XRedPointConditions.Types.CONDITION_FAVORABILITY_DOCUMENT_INFO,
        XRedPointConditions.Types.CONDITION_FAVORABILITY_DOCUMENT_RUMOR,
        XRedPointConditions.Types.CONDITION_FAVORABILITY_DOCUMENT_AUDIO,
        XRedPointConditions.Types.CONDITION_FAVORABILITY_DOCUMENT_ACTION,
        XRedPointConditions.Types.CONDITION_FAVORABILITY_PLOT,
        XRedPointConditions.Types.CONDITION_FAVORABILITY_GIFT,
    }
    return SubCondition
end

function XRedPointConditionFavorability.Check(currCharacter)
    local allCharDatas = XDataCenter.CharacterManager.GetCharacterList()
    for _, v in pairs(allCharDatas or {}) do
        local isOwn = XDataCenter.CharacterManager.IsOwnCharacter(v.Id)
        local isCurrCharacter = (v.Id == currCharacter.CharacterId)
        --未拥有角色与当前选中角色的状态不计算红点
        if isOwn and not isCurrCharacter then
            local args = {}
            args.CharacterId = v.Id
            if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_FAVORABILITY_DOCUMENT_INFO, args) then
                return true
            end

            if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_FAVORABILITY_DOCUMENT_RUMOR, args) then
                return true
            end

            if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_FAVORABILITY_DOCUMENT_AUDIO, args) then
                return true
            end

            if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_FAVORABILITY_DOCUMENT_ACTION, args) then
                return true
            end

            if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_FAVORABILITY_PLOT, args) then
                return true
            end

            if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_FAVORABILITY_GIFT, args) then
                return true
            end
        end
    end

    return false
end



return XRedPointConditionFavorability