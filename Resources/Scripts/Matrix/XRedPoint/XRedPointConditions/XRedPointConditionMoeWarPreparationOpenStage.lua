local XRedPointConditionMoeWarPreparationOpenStage = {}

function XRedPointConditionMoeWarPreparationOpenStage.Check()
    local preparationActivityId = XMoeWarConfig.GetPreparationActivityIdInTime()
    if not preparationActivityId then
        return false
    end

    local openStageIdList = XDataCenter.MoeWarManager.GetPreparationAllOpenStageIdList()
    local openStageIdCount = #openStageIdList
    local redminNum = XMoeWarConfig.GetPreparationActivityRedminNum(preparationActivityId)
    if openStageIdCount >= redminNum then
        return true
    end

    return false
end

return XRedPointConditionMoeWarPreparationOpenStage