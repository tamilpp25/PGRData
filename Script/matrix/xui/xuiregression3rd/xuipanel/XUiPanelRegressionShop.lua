local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")

local XUiPanelRegressionBase = require("XUi/XUiRegression3rd/XUiPanel/XUiPanelRegressionBase")
local XUiGridRegressionShop = require("XUi/XUiRegression3rd/XUiGrid/XUiGridRegressionShop")
local XUiPanelRegressionShop = XClass(XUiPanelRegressionBase, "XUiPanelRegressionShop")

function XUiPanelRegressionShop:OnEnable()
    self:RefreshView()
end

function XUiPanelRegressionShop:Show()
    self:Open()
end

function XUiPanelRegressionShop:Hide()
    self:Close()
end

function XUiPanelRegressionShop:InitUi()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelShopList)
    self.DynamicTable:SetProxy(XUiGridRegressionShop, self, self.RootUi)
    self.DynamicTable:SetDelegate(self)
    self.PanelLbItem.gameObject:SetActiveEx(false)
end

function XUiPanelRegressionShop:RefreshView()
    if not XDataCenter.Regression3rdManager.CheckShopLocalRedPointData() then
        XDataCenter.Regression3rdManager.MarkShopLocalRedPointData()
    end
    local shopId = self.ViewModel:GetShopId()
    if not XTool.IsNumberValid(shopId) then
        XLog.Error("XUiPanelRegressionShop:RefreshView error: shop id is null!!!")
        return
    end
    XShopManager.GetShopInfo(shopId, function() 
        self:ShowView(shopId)
    end)
end

function XUiPanelRegressionShop:ShowView(shopId)
    self.GoodsList = XShopManager.GetShopGoodsListDoNotSortCondition(shopId, true)
    local empty = XTool.IsTableEmpty(self.GoodsList)
    
    self.PanelShopList.gameObject:SetActiveEx(not empty)
    self.PanelNoneShopList.gameObject:SetActiveEx(empty)
    if empty then
        return
    end
    self.DynamicTable:SetDataSource(self.GoodsList)
    self.DynamicTable:ReloadDataSync()
end

function XUiPanelRegressionShop:OnDynamicTableEvent(evt, idx, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.GoodsList[idx])
    end
end

function XUiPanelRegressionShop:GetCurShopId()
    return self.ViewModel:GetShopId()
end

function XUiPanelRegressionShop:RefreshBuy()
    self:ShowView(self:GetCurShopId())
end



return XUiPanelRegressionShop