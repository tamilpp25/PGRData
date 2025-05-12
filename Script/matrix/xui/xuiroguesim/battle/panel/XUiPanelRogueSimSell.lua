local XUiGridRogueSimSell = require("XUi/XUiRogueSim/Battle/Grid/XUiGridRogueSimSell")
local XUiPanelRogueSimProfit = require("XUi/XUiRogueSim/Battle/Panel/XUiPanelRogueSimProfit")
---@class XUiPanelRogueSimSell : XUiNode
---@field private _Control XRogueSimControl
---@field Parent XUiRogueSimPopupRoundEnd
---@field BtnAuto XUiComponent.XUiButton
local XUiPanelRogueSimSell = XClass(XUiNode, "XUiPanelRogueSimSell")

function XUiPanelRogueSimSell:OnStart()
    XUiHelper.RegisterClickEvent(self, self.BtnAuto, self.OnBtnAutoClick)
    self.GridSell.gameObject:SetActiveEx(false)
    self:InitView()
    ---@type XUiGridRogueSimSell[]
    self.GridSellList = {}
    -- 是否自动出售
    self.IsAutoSell = false
end

function XUiPanelRogueSimSell:InitView()
    -- 内容
    self.TxtTips.text = self._Control:GetClientConfig("SellContent")
end

function XUiPanelRogueSimSell:Refresh()
    self:RefreshSell()
    self.IsAutoSell = self._Control:CheckCommodityIsAutoSell()
    self:RefreshAutoSell()
    self:RefreshTotalProfit()
end

-- 刷新出售
function XUiPanelRogueSimSell:RefreshSell()
    local gridName = self.GridSell.gameObject.name
    local sellIds = XEnumConst.RogueSim.CommodityIds
    for index, id in ipairs(sellIds) do
        local grid = self.GridSellList[index]
        if not grid then
            local go = XUiHelper.Instantiate(self.GridSell, self.ListSell)
            grid = XUiGridRogueSimSell.New(go, self)
            self.GridSellList[index] = grid
        end
        grid:Open()
        grid:Refresh(id)
        -- 修改名称引导使用
        grid.GameObject.name = string.format("%s%s", gridName, index)
    end
    for i = #sellIds + 1, #self.GridSellList do
        self.GridSellList[i]:Close()
    end
end

-- 刷新自动出售
function XUiPanelRogueSimSell:RefreshAutoSell()
    self.BtnAuto:SetButtonState(self.IsAutoSell and CS.UiButtonState.Select or CS.UiButtonState.Normal)
end

-- 获取总利润
function XUiPanelRogueSimSell:GetTotalProfit()
    local totalProfit = 0
    for _, grid in pairs(self.GridSellList) do
        totalProfit = totalProfit + grid:GetCurCommodityProfit()
    end
    return totalProfit
end

-- 刷新预计总利润
function XUiPanelRogueSimSell:RefreshTotalProfit()
    if not self.PanelProfitUi then
        ---@type XUiPanelRogueSimProfit
        self.PanelProfitUi = XUiPanelRogueSimProfit.New(self.PanelTotalProfit, self)
    end
    self.PanelProfitUi:Open()
    local totalProfit = self:GetTotalProfit()
    self.PanelProfitUi:RefreshTotalProfit(totalProfit)
end

-- 自动出售
function XUiPanelRogueSimSell:OnBtnAutoClick()
    -- 开启时需要检测是否有利润
    if not self.IsAutoSell and self:GetTotalProfit() <= 0 then
        XUiManager.TipMsg(self._Control:GetClientConfig("AutoSellNoProfitTips"))
        self:RefreshAutoSell()
        return
    end
    self.IsAutoSell = self.BtnAuto:GetToggleState()
    for _, grid in pairs(self.GridSellList) do
        grid:AutoSellChange(self.IsAutoSell)
    end
    self.Parent:CheckAutoSell()
end

-- 检查并修复出售预设计划
function XUiPanelRogueSimSell:CheckAndFixSellPresetPlan()
    if not self.IsAutoSell then
        return
    end
    for _, grid in pairs(self.GridSellList) do
        grid:CheckAndFixSellPresetPlan()
    end
end

return XUiPanelRogueSimSell
