local XUiGridRogueSimResource = require("XUi/XUiRogueSim/Common/XUiGridRogueSimResource")
local XUiPanelRogueSimProfit = require("XUi/XUiRogueSim/Battle/Panel/XUiPanelRogueSimProfit")
---@class XUiGridRogueSimSell : XUiNode
---@field private _Control XRogueSimControl
---@field Parent XUiPanelRogueSimSell
---@field Slider XSlider
local XUiGridRogueSimSell = XClass(XUiNode, "XUiGridRogueSimSell")

function XUiGridRogueSimSell:OnStart()
    XUiHelper.RegisterClickEvent(self, self.BtnSmall, self.OnBtnSmallClick)
    XUiHelper.RegisterClickEvent(self, self.BtnAdd, self.OnBtnAddClick)
    self.Slider.onValueChanged:AddListener(function()
        self:OnSliderValueChanged()
    end)
    -- 单次减少/增加的数值
    self.SingleValue = tonumber(self._Control:GetClientConfig("SellSingleValue", 1))
    -- 第一次进入时的出售数量
    self.FirstEnterSellNumber = 0
    -- 是否第一次进入
    self.IsFirstEnter = true
end

---@param id number 货物Id
function XUiGridRogueSimSell:Refresh(id)
    self.Id = id
    self:RefreshGridResource()
    self:RefreshGrade()
    self:RefreshProfit()
end

-- 获取当前货物利润
function XUiGridRogueSimSell:GetCurCommodityProfit()
    if self.PanelProfitUi then
        return self.PanelProfitUi:GetCurCommodityProfit()
    end
    return 0
end

function XUiGridRogueSimSell:RefreshGridResource()
    if not self.Resource then
        ---@type XUiGridRogueSimResource
        self.Resource = XUiGridRogueSimResource.New(self.GridResource, self)
    end
    self.Resource:Open()
    self.Resource:SetShowStatus(true, false, true)
    self.Resource:SetRCBubble()
    self.Resource:Refresh(self.Id)
end

-- 刷新出售数量
function XUiGridRogueSimSell:RefreshGrade()
    -- 拥有的货物数量
    self.CommodityOwnCount = self._Control.ResourceSubControl:GetCommodityOwnCount(self.Id)
    -- 总数量
    self.TxtTotalNum.text = string.format("/%d", self.CommodityOwnCount)
    -- 当前出售数量
    local curSellNumber = self._Control:GetActualCommoditySellCount(self.Id)
    -- 第一次进入时的出售数量
    if self.IsFirstEnter then
        self.FirstEnterSellNumber = curSellNumber
        self.IsFirstEnter = false
    end
    -- 刷新出售数量
    self.TxtNum.text = curSellNumber
    --更新滑动条可滑动区域单位范围
    self.Slider:SetBorderValue(0, self.CommodityOwnCount)
    -- 滑动条
    self.Slider.minValue = 0
    self.Slider.maxValue = self.CommodityOwnCount
    self.Slider.value = curSellNumber
end

-- 刷新利润
function XUiGridRogueSimSell:RefreshProfit()
    if not self.PanelProfitUi then
        ---@type XUiPanelRogueSimProfit
        self.PanelProfitUi = XUiPanelRogueSimProfit.New(self.PanelProfit, self)
    end
    self.PanelProfitUi:Open()
    self.PanelProfitUi:RefreshSellProfit(self.Id, XEnumConst.RogueSim.Alignment.RTB)
end

function XUiGridRogueSimSell:OnBtnSmallClick()
    self:SetSliderValue(-self.SingleValue)
end

function XUiGridRogueSimSell:OnBtnAddClick()
    self:SetSliderValue(self.SingleValue)
end

function XUiGridRogueSimSell:SetSliderValue(value)
    local curSellNumber = self._Control:GetActualCommoditySellCount(self.Id)
    local newSellNumber = XMath.Clamp(curSellNumber + value, 0, self.CommodityOwnCount)
    local isSame = curSellNumber == newSellNumber
    self.Slider.value = newSellNumber
    if isSame then
        self:OnSliderValueChanged()
    end
end

function XUiGridRogueSimSell:OnSliderValueChanged()
    local curSellNumber = XMath.ToMinInt(self.Slider.value)
    self._Control:UpdateTempSellPlan(self.Id, curSellNumber)
    -- 刷新出售数量
    self.TxtNum.text = curSellNumber
    -- 刷新利润
    self:RefreshProfit()
    self.Parent:RefreshTotalProfit()
end

-- 自动出售
function XUiGridRogueSimSell:AutoSellChange(value)
    local curSellPresetCount = 0
    if value and self.CommodityOwnCount > 0 then
        local curSellNumber = self._Control:GetActualCommoditySellCount(self.Id)
        -- 向上取整
        local preset = math.ceil(curSellNumber / self.CommodityOwnCount * XEnumConst.RogueSim.Denominator)
        curSellPresetCount = XMath.Clamp(preset, 0, XEnumConst.RogueSim.Denominator)
    end
    self._Control:UpdateTempSellPresetPlan(self.Id, curSellPresetCount)
end

-- 检查并修复出售预设计划
function XUiGridRogueSimSell:CheckAndFixSellPresetPlan()
    local curSellNumber = self._Control:GetActualCommoditySellCount(self.Id)
    -- 出售数量未发生变化
    if self.FirstEnterSellNumber == curSellNumber then
        return
    end
    local preset = 0
    if self.CommodityOwnCount > 0 then
        -- 向上取整
        preset = math.ceil(curSellNumber / self.CommodityOwnCount * XEnumConst.RogueSim.Denominator)
        preset = XMath.Clamp(preset, 0, XEnumConst.RogueSim.Denominator)
    end
    local curSellPresetCount = self._Control:GetActualCommoditySellPresetCount(self.Id)
    if curSellPresetCount ~= preset then
        self._Control:UpdateTempSellPresetPlan(self.Id, preset)
    end
end

return XUiGridRogueSimSell
