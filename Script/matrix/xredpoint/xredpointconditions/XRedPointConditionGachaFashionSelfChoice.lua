local XRedPointConditionGachaFashionSelfChoice = {}

function XRedPointConditionGachaFashionSelfChoice.Check()
    local activityId = XDataCenter.GachaManager.GetCurGachaFashionSelfChoiceActivityId()
    if not XTool.IsNumberValid(activityId) then
        return false
    end

    local curGachaId = XDataCenter.GachaManager.GetCurSelfChoiceSelectGachId()
    if XTool.IsNumberValid(curGachaId) then -- 已经选择了就不需要蓝点了
        return false
    end

    local data = XSaveTool.GetData("OpenUiGachaFashionSelfChoiceEntrance")
    if not data then
        return true
    end

    if data.NextCanShowTimeStamp and XTime.GetServerNowTimestamp() > data.NextCanShowTimeStamp then
        return true
    end

    return false
end

return XRedPointConditionGachaFashionSelfChoice