---@class XUiGridRogueSimRoundSettlementSell : XUiNode
---@field private _Control XRogueSimControl
local XUiGridRogueSimRoundSettlementSell = XClass(XUiNode, "XUiGridRogueSimRoundSettlementSell")

function XUiGridRogueSimRoundSettlementSell:OnStart()
    XUiHelper.RegisterClickEvent(self, self.BtnSell, self.OnBtnSellClick)
end

function XUiGridRogueSimRoundSettlementSell:Refresh(id)
    self.Id = id
    -- 货物图标
    self.RImgResource:SetRawImage(self._Control.ResourceSubControl:GetCommodityIcon(id))
    -- 出售数量
    local sellNum = self._Control.ResourceSubControl:GetSellPlanActualCount(id)
    self.TxtSellNum.text = string.format("-%d", sellNum)
    -- 利润
    local singleProfit = self._Control.ResourceSubControl:GetCommodityTotalPrice(id)
    self.CurCommodityProfit = singleProfit * sellNum
    self.TxtProfit.text = string.format("+%d", self.CurCommodityProfit)
    -- 金币图标
    local goldId = XEnumConst.RogueSim.ResourceId.Gold
    self.RImgCoin:SetRawImage(self._Control.ResourceSubControl:GetResourceIcon(goldId))
end

function XUiGridRogueSimRoundSettlementSell:GetCurCommodityProfit()
    return self.CurCommodityProfit or 0
end

function XUiGridRogueSimRoundSettlementSell:OnBtnSellClick()
    XLuaUiManager.Open("UiRogueSimComponent", XEnumConst.RogueSim.BubbleType.Property, self.Transform, self.Id, {
        IsPrice = true,
    })
end

return XUiGridRogueSimRoundSettlementSell
