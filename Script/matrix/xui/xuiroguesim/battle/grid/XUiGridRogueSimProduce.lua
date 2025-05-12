local XUiGridRogueSimResource = require("XUi/XUiRogueSim/Common/XUiGridRogueSimResource")
local XUiPanelRogueSimFluctuate = require("XUi/XUiRogueSim/Battle/Panel/XUiPanelRogueSimFluctuate")
local XUiPanelRogueSimProfit = require("XUi/XUiRogueSim/Battle/Panel/XUiPanelRogueSimProfit")
---@class XUiGridRogueSimProduce : XUiNode
---@field private _Control XRogueSimControl
---@field Parent XUiPanelRogueSimProduce
local XUiGridRogueSimProduce = XClass(XUiNode, "XUiGridRogueSimProduce")

function XUiGridRogueSimProduce:OnStart()
    XUiHelper.RegisterClickEvent(self, self.BtnDetail, self.OnBtnDetailClick)
    XUiHelper.RegisterClickEvent(self, self.BtnMinus, self.OnBtnMinusClick)
    XUiHelper.RegisterClickEvent(self, self.BtnAdd, self.OnBtnAddClick)
    self.TxtFull.gameObject:SetActiveEx(false)
    self.PanelDetail.gameObject:SetActiveEx(true)
    self.ImgBgUp.gameObject:SetActiveEx(false)
    self.ImgBgDown.gameObject:SetActiveEx(false)
    self.ImgBgNormal.gameObject:SetActiveEx(true)
    -- 单次减少/增加的数值
    self.SingleValue = 1
    -- 货物评分
    self.Score = 0
end

---@param id number 货物Id
function XUiGridRogueSimProduce:Refresh(id)
    self.Id = id
    self:RefreshGridResource()
    self:RefreshCommodityScore()
    self:RefreshNum()
    self:RefreshFluctuations()
    self:RefreshProfit()
    self:RefreshPopulation()
    self:RefreshPopulationBtn()
end

-- 获取货物Id
function XUiGridRogueSimProduce:GetCommodityId()
    return self.Id
end

-- 获取货物评分
function XUiGridRogueSimProduce:GetCommodityScore()
    return self.Score or 0
end

-- 获取当前货物利润
function XUiGridRogueSimProduce:GetCurCommodityProfit()
    if self.PanelProfitUi then
        return self.PanelProfitUi:GetCurCommodityProfit()
    end
    return 0
end

-- 刷新资源
function XUiGridRogueSimProduce:RefreshGridResource()
    if not self.Resource then
        ---@type XUiGridRogueSimResource
        self.Resource = XUiGridRogueSimResource.New(self.GridResource, self)
    end
    self.Resource:Open()
    self.Resource:SetShowStatus(true)
    self.Resource:SetRCBubble()
    self.Resource:Refresh(self.Id)
end

-- 刷新货物评分
function XUiGridRogueSimProduce:RefreshCommodityScore()
    -- 分数和背景颜色
    local score, bgColor = self._Control.ResourceSubControl:GetCommodityProduceScoreAndColor(self.Id)
    self.Score = score
    self.TxtEfficiency.text = score
    self.ImgBgNormal.color = bgColor
end

-- 刷新生产数量
function XUiGridRogueSimProduce:RefreshNum()
    -- 预估产量
    local produceRate = self._Control.ResourceSubControl:GetCommodityTotalProduceRate(self.Id)
    self.TxtNum.text = produceRate
    -- 是否溢出
    local isFull = self._Control.ResourceSubControl:CheckProduceRateIsExceedLimit(self.Id)
    self.TxtFull.gameObject:SetActiveEx(isFull)
end

-- 刷新价格波动
function XUiGridRogueSimProduce:RefreshFluctuations()
    if not self.PanelFluctuationsUi then
        ---@type XUiPanelRogueSimFluctuate
        self.PanelFluctuationsUi = XUiPanelRogueSimFluctuate.New(self.PanelFluctuations, self)
    end
    self.PanelFluctuationsUi:Open()
    self.PanelFluctuationsUi:Refresh(self.Id)
end

-- 刷新预计利润
function XUiGridRogueSimProduce:RefreshProfit()
    if not self.PanelProfitUi then
        ---@type XUiPanelRogueSimProfit
        self.PanelProfitUi = XUiPanelRogueSimProfit.New(self.PanelProfit, self)
    end
    self.PanelProfitUi:Open()
    self.PanelProfitUi:RefreshProduceProfit(self.Id, XEnumConst.RogueSim.Alignment.RTB)
end

-- 刷新生产力
function XUiGridRogueSimProduce:RefreshPopulation()
    self.TxtPoint.text = self._Control:GetActualCommodityPopulationCount(self.Id)
end

-- 刷新按钮
function XUiGridRogueSimProduce:RefreshPopulationBtn()
    local curPopulation = self._Control:GetActualCommodityPopulationCount(self.Id)
    local remainingPopulation = self._Control:GetActualRemainingPopulation()
    self.BtnMinus:SetDisable(curPopulation <= 0)
    self.BtnAdd:SetDisable(remainingPopulation <= 0)
end

-- 改变生产力数量
function XUiGridRogueSimProduce:ChangePopulationCount()
    self:RefreshCommodityScore()
    self:RefreshPopulation()
end

-- 处理按钮点击
function XUiGridRogueSimProduce:HandelBtnClick(value)
    local remainingPopulation = self._Control:GetActualRemainingPopulation()
    local curPopulation = self._Control:GetActualCommodityPopulationCount(self.Id)
    if value > 0 and remainingPopulation < value then
        return
    elseif value < 0 and curPopulation <= 0 then
        return
    end
    local newPopulation = math.max(0, curPopulation + value)
    self._Control:UpdateTempProducePlan(self.Id, newPopulation)
    self:ChangePopulationCount()
    self.Parent:RefreshPopulation()
    self.Parent:RefreshPopulationChange()
end

function XUiGridRogueSimProduce:OnBtnDetailClick()
    XLuaUiManager.Open("UiRogueSimComponent", XEnumConst.RogueSim.BubbleType.Property, self.BtnDetail.transform, self.Id)
end

-- 减少生产力
function XUiGridRogueSimProduce:OnBtnMinusClick()
    self:HandelBtnClick(-self.SingleValue)
end

-- 增加生产力
function XUiGridRogueSimProduce:OnBtnAddClick()
    self:HandelBtnClick(self.SingleValue)
end

return XUiGridRogueSimProduce
