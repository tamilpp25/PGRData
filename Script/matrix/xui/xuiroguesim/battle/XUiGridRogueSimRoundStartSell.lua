---@class XUiGridRogueSimRoundStartSell : XUiNode
---@field private _Control XRogueSimControl
local XUiGridRogueSimRoundStartSell = XClass(XUiNode, "XUiGridRogueSimRoundStartSell")

---@param info XRogueSimCommoditySellResultItem
function XUiGridRogueSimRoundStartSell:Refresh(info)
    self.Id = info:GetCommodityId()
    -- 货物图标
    self.RImgResource:SetRawImage(self._Control.ResourceSubControl:GetCommodityIcon(self.Id))
    -- 出售数量
    self.TxtSellNum.text = string.format("-%d", info:GetSellCount())
    -- 利润
    self.TxtProfit.text = string.format("+%d", info:GetSellAwardCount())
    -- 金币图标
    local goldId = XEnumConst.RogueSim.ResourceId.Gold
    self.RImgCoin:SetRawImage(self._Control.ResourceSubControl:GetResourceIcon(goldId))
    -- 是否暴击
    self.ImgAddition.gameObject:SetActiveEx(info:GetIsCritical())
    local color = self._Control:GetClientConfig("RoundStartSellPriceColor", info:GetIsCritical() and 2 or 1)
    self.TxtProfit.color = XUiHelper.Hexcolor2Color(color)
end

return XUiGridRogueSimRoundStartSell
