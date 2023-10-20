---@class XUiRogueSimSell : XLuaUi
---@field private _Control XRogueSimControl
---@field private AssetPanel XUiPanelRogueSimAsset
local XUiRogueSimSell = XLuaUiManager.Register(XLuaUi, "UiRogueSimSell")

function XUiRogueSimSell:OnAwake()
    self:RegisterUiEvents()
    self.GridSell.gameObject:SetActiveEx(false)
    ---@type XUiGridRogueSimSell[]
    self.GridSellList = {}
end

function XUiRogueSimSell:OnStart()
    -- 显示资源
    self.AssetPanel = require("XUi/XUiRogueSim/Common/XUiPanelRogueSimAsset").New(
        self.PanelAsset,
        self,
        XEnumConst.RogueSim.ResourceId.Gold,
        XEnumConst.RogueSim.CommodityIds)
    self.AssetPanel:Open()
    self:InitView()
end

function XUiRogueSimSell:OnEnable()
    self:RefreshGridSell()
    self:RefreshProfit()
end

function XUiRogueSimSell:InitView()
    -- 内容
    self.TxtTips.text = self._Control:GetClientConfig("SellContent")
end

function XUiRogueSimSell:RefreshGridSell()
    local sellIds = XEnumConst.RogueSim.CommodityIds
    for index, id in ipairs(sellIds) do
        local grid = self.GridSellList[index]
        if not grid then
            local go = XUiHelper.Instantiate(self.GridSell, self.SellList)
            grid = require("XUi/XUiRogueSim/Sell/XUiGridRogueSimSell").New(go, self)
            self.GridSellList[index] = grid
        end
        grid:Open()
        grid:Refresh(id)
    end
    for i = #sellIds + 1, #self.GridSellList do
        self.GridSellList[i]:Close()
    end
end

function XUiRogueSimSell:RefreshProfit()
    -- 金币
    local goldId = XEnumConst.RogueSim.ResourceId.Gold
    self.RImgCoin:SetRawImage(self._Control.ResourceSubControl:GetResourceIcon(goldId))
    -- 总利润
    local totalProfit = 0
    for _, grid in pairs(self.GridSellList) do
        if grid:IsNodeShow() then
            totalProfit = totalProfit + grid:GetCurCommodityProfit()
        end
    end
    self.TxtProfit.text = totalProfit
    -- 刷新按钮
    local sellPlan = self:GetActualSellCount()
    local isChange = self._Control.ResourceSubControl:CheckActualSellCountIsChange(sellPlan)
    -- 没有变化且装车数量为空时按钮置灰
    self.BtnYes:SetDisable(not isChange and XTool.IsTableEmpty(sellPlan))
end

-- 获取实际出售数量
function XUiRogueSimSell:GetActualSellCount()
    local sellPlan = {}
    for _, grid in pairs(self.GridSellList) do
        if grid:IsNodeShow() then
            local id = grid:GetId()
            local num = grid:GetCurSellNumber()
            if XTool.IsNumberValid(num) then
                sellPlan[id] = num
            end
        end
    end
    return sellPlan
end

function XUiRogueSimSell:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick)
    XUiHelper.RegisterClickEvent(self, self.BtnYes, self.OnBtnYesClick)
end

function XUiRogueSimSell:OnBtnCloseClick()
    self:Close()
end

function XUiRogueSimSell:OnBtnYesClick()
    local sellPlan = self:GetActualSellCount()
    if not self._Control.ResourceSubControl:CheckActualSellCountIsChange(sellPlan) then
        if XTool.IsTableEmpty(sellPlan) then
            XUiManager.TipMsg(self._Control:GetClientConfig("SellChangeContent", 2))
        else
            self:Close()
        end
        return
    end
    self._Control:RogueSimCommoditySetupSellRequest(sellPlan, function()
        XUiManager.PopupLeftTip(self._Control:GetClientConfig("SellChangeContent", 1))
        self:Close()
    end)
end

return XUiRogueSimSell
