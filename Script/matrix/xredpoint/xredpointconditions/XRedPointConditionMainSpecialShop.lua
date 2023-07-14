-- 特殊商店红点检测
local XRedPointConditionMainSpecialShop = {}

function XRedPointConditionMainSpecialShop.Check()
    if XDataCenter.SpecialShopManager:IsShowEntrance() then
        return not XSaveTool.GetData(string.format("%d%s", XPlayer.Id, "SpecialShopAlreadyIn"))
    else
        return false
    end
end

return XRedPointConditionMainSpecialShop