---@class XUiGridRogueSimProduce : XUiNode
---@field private _Control XRogueSimControl
---@field private BtnSwitch UnityEngine.UI.Toggle
local XUiGridRogueSimProduce = XClass(XUiNode, "XUiGridRogueSimProduce")

function XUiGridRogueSimProduce:OnStart()
    XUiHelper.RegisterClickEvent(self, self.BtnProfit, self.OnBtnProfitClick)
end

function XUiGridRogueSimProduce:Refresh(id)
    self.Id = id
    self:RefreshGridResource()
    self:RefreshRate()
end

-- 获取Toggle
function XUiGridRogueSimProduce:GetBtnToggle()
    return self.BtnToggle
end

-- 刷新资源
function XUiGridRogueSimProduce:RefreshGridResource()
    if not self.Resource then
        ---@type XUiGridRogueSimResource
        self.Resource = require("XUi/XUiRogueSim/Common/XUiGridRogueSimResource").New(self.GridResource, self)
    end
    self.Resource:Open()
    self.Resource:SetShowStatus(true)
    self.Resource:SetRCBubble()
    self.Resource:Refresh(self.Id)
end

-- 刷新效率
function XUiGridRogueSimProduce:RefreshRate()
    -- 预估产量
    local produceRate = self._Control.ResourceSubControl:GetCommodityTotalProduceRate(self.Id)
    self.TxtNum.text = produceRate
    -- 货物价格
    local price = self._Control.ResourceSubControl:GetCommodityTotalPrice(self.Id)
    -- 预计利润 = 价格 * 产量
    local goldId = XEnumConst.RogueSim.ResourceId.Gold
    self.RImgCoin:SetRawImage(self._Control.ResourceSubControl:GetResourceIcon(goldId))
    self.TxtProfit.text = price * produceRate
end

function XUiGridRogueSimProduce:OnBtnProfitClick()
    XLuaUiManager.Open("UiRogueSimComponent", XEnumConst.RogueSim.BubbleType.Property, self.BtnProfit.transform, self.Id)
end

return XUiGridRogueSimProduce
