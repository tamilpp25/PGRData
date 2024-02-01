---@class XUiGridRogueSimSell : XUiNode
---@field private _Control XRogueSimControl
---@field Parent XUiRogueSimSell
---@field Slider XSlider
local XUiGridRogueSimSell = XClass(XUiNode, "XUiGridRogueSimSell")

function XUiGridRogueSimSell:OnStart()
    XUiHelper.RegisterClickEvent(self, self.BtnSub, self.OnBtnSubClick)
    XUiHelper.RegisterClickEvent(self, self.BtnAdd, self.OnBtnAddClick)
    self.Slider.onValueChanged:AddListener(function()
        self:OnSliderValueChanged()
    end)
    self.CurSellNumber = 0
end

function XUiGridRogueSimSell:Refresh(id)
    self.Id = id
    self:RefreshGridResource()
    self:RefreshGrade()
    self:RefreshProfit()
end

function XUiGridRogueSimSell:GetId()
    return self.Id
end

-- 获取当前出售数量
function XUiGridRogueSimSell:GetCurSellNumber()
    return self.CurSellNumber or 0
end

-- 获取当前货物利润
function XUiGridRogueSimSell:GetCurCommodityProfit()
    return self.CurCommodityProfit or 0
end

function XUiGridRogueSimSell:RefreshGridResource()
    if not self.Resource then
        ---@type XUiGridRogueSimResource
        self.Resource = require("XUi/XUiRogueSim/Common/XUiGridRogueSimResource").New(self.GridResource, self)
    end
    self.Resource:Open()
    self.Resource:SetShowStatus(true)
    self.Resource:SetRCBubble()
    self.Resource:Refresh(self.Id)
end

-- 刷新出售数量
function XUiGridRogueSimSell:RefreshGrade()
    -- 拥有的货物数量
    self.CommodityOwnCount = self._Control.ResourceSubControl:GetCommodityOwnCount(self.Id)
    -- 总数量
    self.TxtTotalNum.text = string.format("/%d", self.CommodityOwnCount)
    -- 单次减少/增加的数值
    self.SingleValue = tonumber(self._Control:GetClientConfig("SellSingleValue", 1))
    -- 当前值
    self.CurSellNumber = self._Control.ResourceSubControl:GetSellPlanActualCount(self.Id)
    -- 刷新出售数量
    self.TxtNum.text = self.CurSellNumber
    --更新滑动条可滑动区域单位范围
    self.Slider:SetBorderValue(0, self.CommodityOwnCount)
    -- 滑动条
    self.Slider.minValue = 0
    self.Slider.maxValue = self.CommodityOwnCount
    self.Slider.value = self.CurSellNumber
end

-- 刷新利润
function XUiGridRogueSimSell:RefreshProfit()
    -- 金币图标
    local goldId = XEnumConst.RogueSim.ResourceId.Gold
    self.RImgCoin:SetRawImage(self._Control.ResourceSubControl:GetResourceIcon(goldId))
    -- 货物价格
    local singleProfit = self._Control.ResourceSubControl:GetCommodityTotalPrice(self.Id)
    self.CurCommodityProfit = singleProfit * self.CurSellNumber
    self.TxtProfit.text = self.CurCommodityProfit
end

function XUiGridRogueSimSell:OnBtnSubClick()
    self:SetSliderValue(self.CurSellNumber - self.SingleValue)
end

function XUiGridRogueSimSell:OnBtnAddClick()
    self:SetSliderValue(self.CurSellNumber + self.SingleValue)
end

function XUiGridRogueSimSell:SetSliderValue(value)
    value = XMath.Clamp(value, 0, self.CommodityOwnCount)
    local isSame = self.CurSellNumber == value
    self.Slider.value = value
    if isSame then
        self:OnSliderValueChanged()
    end
end

function XUiGridRogueSimSell:OnSliderValueChanged()
    self.CurSellNumber = XMath.ToMinInt(self.Slider.value)
    -- 刷新出售数量
    self.TxtNum.text = self.CurSellNumber
    -- 刷新利润
    self:RefreshProfit()
    self.Parent:RefreshProfit()
end

return XUiGridRogueSimSell
