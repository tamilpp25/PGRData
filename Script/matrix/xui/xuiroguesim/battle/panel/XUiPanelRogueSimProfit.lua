-- 预计收益面板
local XUiCommonRollingNumber = require("XUi/XUiCommon/XUiCommonRollingNumber")
---@class XUiPanelRogueSimProfit : XUiNode
---@field private _Control XRogueSimControl
local XUiPanelRogueSimProfit = XClass(XUiNode, "XUiPanelRogueSimProfit")

function XUiPanelRogueSimProfit:OnStart()
    if self.BtnDetail then
        XUiHelper.RegisterClickEvent(self, self.BtnDetail, self.OnBtnDetailClick)
    end
    if not self.Effect then
        self.Effect = XUiHelper.TryGetComponent(self.TxtProfit.transform, "Effect")
    end
    if self.Effect then
        self.Effect.gameObject:SetActive(false)
    end
    -- 当前货物利润
    self.CurCommodityProfit = 0
    -- 滚动数字时长
    local time = self._Control:GetClientConfig("RollingNumberTime")
    self.RollingNumberTime = tonumber(time) / 1000
end

function XUiPanelRogueSimProfit:OnDisable()
    if self.RollingNumber then
        self.RollingNumber:Kill()
    end
end

-- 获取当前货物利润
function XUiPanelRogueSimProfit:GetCurCommodityProfit()
    return self.CurCommodityProfit or 0
end

---@param id number 货物Id
function XUiPanelRogueSimProfit:RefreshProduceProfit(id, alignment)
    self.Id = id
    self.CurAlignment = alignment
    self.IsPrice = true
    -- 金币图标
    local goldId = XEnumConst.RogueSim.ResourceId.Gold
    self.RImgCoin:SetRawImage(self._Control.ResourceSubControl:GetResourceIcon(goldId))
    -- 货物价格
    local singleProfit = self._Control.ResourceSubControl:GetCommodityTotalPrice(id)
    -- 预估产量
    local produceRate = self._Control.ResourceSubControl:GetCommodityTotalProduceRate(id)
    -- 预计利润 = 价格 * 产量
    self.CurCommodityProfit = singleProfit * produceRate
    self.TxtProfit.text = self.CurCommodityProfit
end

---@param id number 货物Id
function XUiPanelRogueSimProfit:RefreshSellProfit(id, alignment)
    self.Id = id
    self.CurAlignment = alignment
    self.IsPrice = true
    -- 金币图标
    local goldId = XEnumConst.RogueSim.ResourceId.Gold
    self.RImgCoin:SetRawImage(self._Control.ResourceSubControl:GetResourceIcon(goldId))
    -- 货物价格
    local singleProfit = self._Control.ResourceSubControl:GetCommodityTotalPrice(id)
    -- 出售数量
    local sellNumber = self._Control:GetActualCommoditySellCount(id)
    -- 预计利润 = 价格 * 数量
    self.CurCommodityProfit = singleProfit * sellNumber
    self.TxtProfit.text = self.CurCommodityProfit
end

---@param totalProfit number 总利润
---@param isAnim boolean 是否播放动画
function XUiPanelRogueSimProfit:RefreshTotalProfit(totalProfit, isAnim)
    -- 金币图标
    local goldId = XEnumConst.RogueSim.ResourceId.Gold
    self.RImgCoin:SetRawImage(self._Control.ResourceSubControl:GetResourceIcon(goldId))
    -- 总利润
    if not isAnim or self.TotalProfit == totalProfit then
        self.TotalProfit = totalProfit
        self.TxtProfit.text = string.format("+%s", totalProfit)
    else
        local startProfit = self.TotalProfit or 0
        local endProfit = totalProfit
        self.TotalProfit = totalProfit
        self:PlayRollingNumber(startProfit, endProfit)
    end
end

-- 播放数字滚动动画
---@param startProfit number 起始利润
---@param endProfit number 结束利润
function XUiPanelRogueSimProfit:PlayRollingNumber(startProfit, endProfit)
    if not self.RollingNumber then
        ---@type XUiCommonRollingNumber
        self.RollingNumber = XUiCommonRollingNumber.New(handler(self, self.RollingStart), handler(self, self.RollingRefresh), handler(self, self.RollingEnd))
    end
    if self.RollingNumber:IsActive() then
        self.RollingNumber:ChangeEndValue(endProfit, self.RollingNumberTime)
    else
        self.RollingNumber:Play(startProfit, endProfit, self.RollingNumberTime)
    end
end

function XUiPanelRogueSimProfit:RollingStart()
    if self.Effect then
        self.Effect.gameObject:SetActive(true)
    end
end

function XUiPanelRogueSimProfit:RollingRefresh(value)
    self.TxtProfit.text = string.format("+%s", value)
end

function XUiPanelRogueSimProfit:RollingEnd()
    self.TxtProfit.text = string.format("+%s", self.TotalProfit)
    if self.Effect then
        self.Effect.gameObject:SetActive(false)
    end
end

function XUiPanelRogueSimProfit:OnBtnDetailClick()
    XLuaUiManager.Open("UiRogueSimComponent", XEnumConst.RogueSim.BubbleType.Property, self.BtnDetail.transform, self.Id, {
        IsPrice = self.IsPrice or false,
        Alignment = self.CurAlignment or XEnumConst.RogueSim.Alignment.LC,
    })
end

return XUiPanelRogueSimProfit
