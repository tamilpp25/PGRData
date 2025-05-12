local XRedPointConditionLottoFashionSelfChoice = {}

function XRedPointConditionLottoFashionSelfChoice.Check()
    local lottoPrimaryId = XDataCenter.LottoManager.GetCurSelfChoiceLottoPrimaryId()
    if not XTool.IsNumberValid(lottoPrimaryId) then
        return false
    end

    local curLottoId = XDataCenter.LottoManager.GetCurSelectedLottoIdByPrimartLottoId(lottoPrimaryId)
    if XTool.IsNumberValid(curLottoId) then -- 已经选择了就不需要蓝点了
        return false
    end

    local data = XSaveTool.GetData("OpenUiLottoFashionSelfChoiceEntrance")
    if not data then
        return true
    end

    if data.NextCanShowTimeStamp and XTime.GetServerNowTimestamp() > data.NextCanShowTimeStamp then
        return true
    end

    return false
end

return XRedPointConditionLottoFashionSelfChoice