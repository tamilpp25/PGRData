----------------------------------------------------------------
-- 周卡奖励领取
local XRedPointConditionGetWeekCard = {}

function XRedPointConditionGetWeekCard.Check(weekCardId)
    if XTool.IsNumberValid(weekCardId) then
        ---@field weekCardData XPurchaseWeekCardData
        local weekCardData = XDataCenter.PurchaseManager.GetWeekCardDataBySignInId(weekCardId)
        if weekCardData then
            return not weekCardData:GetIsGotToday()
        end
    else
        local weekCardDataList = XDataCenter.PurchaseManager.GetWeekCardDatas()
        for _, weekCardData in pairs(weekCardDataList) do
            if weekCardData and not weekCardData:GetIsGotToday() then
                return true
            end
        end
    end
    
    return false
end

return XRedPointConditionGetWeekCard