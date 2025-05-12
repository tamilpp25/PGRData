----------------------------------------------------------------
--资料检测：只关心依赖度等级变化，需要参数characterId，动作有变化也检查
local XRedPointConditionFavorabilityAction = {}
local Events = nil
function XRedPointConditionFavorabilityAction.GetSubEvents()
    Events = Events or {
        XRedPointEventElement.New(XEventId.EVENT_FAVORABILITY_LEVELCHANGED),
        XRedPointEventElement.New(XEventId.EVENT_FAVORABILITY_ACTIONUNLOCK),
    }
    return Events
end

function XRedPointConditionFavorabilityAction.Check(checkArgs)
    if not checkArgs then return false end
    local characterId = checkArgs.CharacterId
    if characterId == nil then return false end
    local isOpen = XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.FavorabilityFile)
    if not isOpen then return false end
    return XMVCA.XFavorability:HasActionToBeUnlock(characterId)
end

return XRedPointConditionFavorabilityAction