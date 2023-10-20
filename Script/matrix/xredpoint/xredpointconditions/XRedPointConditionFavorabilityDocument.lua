----------------------------------------------------------------
--单个邮件检测
local XRedPointConditionFavorabilityDocument = {}

local SubCondition = nil
function XRedPointConditionFavorabilityDocument.GetSubConditions()
    SubCondition = SubCondition or {
        XRedPointConditions.Types.CONDITION_FAVORABILITY_DOCUMENT_INFO ,
        XRedPointConditions.Types.CONDITION_FAVORABILITY_DOCUMENT_RUMOR,
        XRedPointConditions.Types.CONDITION_FAVORABILITY_DOCUMENT_AUDIO,
    }
    return SubCondition
end

function XRedPointConditionFavorabilityDocument.Check(checkArgs)
    if XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.FavorabilityFile) then
        return false
    end

    if not checkArgs then return false end
    local characterId = checkArgs.CharacterId
    if characterId == nil then return false end

    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_FAVORABILITY_DOCUMENT_INFO, checkArgs) then
        return true
    end

    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_FAVORABILITY_DOCUMENT_RUMOR, checkArgs) then
        return true
    end

    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_FAVORABILITY_DOCUMENT_AUDIO, checkArgs) then
        return true
    end

    return false
end



return XRedPointConditionFavorabilityDocument