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
            if XRedPointConditionFavorabilityInfo.Check(args) then
                return true
            end

            if XRedPointConditionFavorabilityRumor.Check(args) then
                return true
            end

            if XRedPointConditionFavorabilityAudio.Check(args) then
                return true
            end

            if XRedPointConditionFavorabilityAction.Check(args) then
                return true
            end

            if XRedPointConditionFavorabilityPlot.Check(args) then
                return true
            end

            if XRedPointConditionFavorabilityGift.Check(args) then
                return true
            end
        end
    end

    return false
end



return XRedPointConditionFavorability