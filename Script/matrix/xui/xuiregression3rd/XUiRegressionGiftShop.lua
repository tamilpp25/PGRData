
local XUiGridRegressionGift = require("XUi/XUiRegression3rd/XUiGrid/XUiGridRegressionGift")

local XUiRegressionGiftShop = XLuaUiManager.Register(XLuaUi, "UiRegressionGiftShop")

function XUiRegressionGiftShop:OnAwake()
    self.ViewModel = XDataCenter.Regression3rdManager.GetViewModel()
    self:InitCb()
    self:InitUi()
end 

function XUiRegressionGiftShop:OnStart()
    self:RequestPurchase()
    self:InitView()
end

function XUiRegressionGiftShop:OnEnable()
    self.Super.OnEnable(self)
    self:UpdateTime()
    if not self.Timer then
        self.Timer = XScheduleManager.ScheduleForever(function() 
            self:UpdateTime()
        end, XScheduleManager.SECOND * 60)
    end
end

function XUiRegressionGiftShop:OnDisable()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiRegressionGiftShop:InitCb()
    self:BindExitBtns()
end 

function XUiRegressionGiftShop:InitUi()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelItemList)
    self.DynamicTable:SetProxy(XUiGridRegressionGift)
    self.DynamicTable:SetDelegate(self)
    self.GridShop.gameObject:SetActiveEx(false)
end 

function XUiRegressionGiftShop:SetupDynamicTable()
    local empty = XTool.IsTableEmpty(self.PurchaseList)
    self.ImgEmpty.gameObject:SetActiveEx(empty)
    if empty then
        return
    end
    self:SortPurchase()
    self.DynamicTable:SetDataSource(self.PurchaseList)
    self.DynamicTable:ReloadDataSync()
end 

function XUiRegressionGiftShop:RequestPurchase()
    local uiType = self.ViewModel:GetPackageUiType()
    self.UiType = uiType
    XDataCenter.PurchaseManager.GetPurchaseListRequest( { uiType }, function()
        self.PurchaseList = XDataCenter.PurchaseManager.GetDatasByUiType(uiType) or {}
        self:SetupDynamicTable()
    end)
end

function XUiRegressionGiftShop:OnDynamicTableEvent(evt, idx, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(handler(self, self.SetupDynamicTable))
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.PurchaseList[idx])
    end
end 

function XUiRegressionGiftShop:SortPurchase()
    if XTool.IsTableEmpty(self.PurchaseList) then
        return
    end
    table.sort(self.PurchaseList, function(a, b) 
        local aSellOut = a.BuyLimitTimes and a.BuyLimitTimes > 0 and a.BuyTimes >= a.BuyLimitTimes
        local bSellOut = b.BuyLimitTimes and b.BuyLimitTimes > 0 and b.BuyTimes >= b.BuyLimitTimes
        if aSellOut ~= bSellOut then
            return bSellOut
        end
        if a.Priority ~= b.Priority then
            return a.Priority < b.Priority
        end
        return a.Id < b.Id
    end)
end

function XUiRegressionGiftShop:InitView()
    self.AssetPanel = XUiHelper.NewPanelActivityAsset({ XDataCenter.ItemManager.ItemId.HongKa }, self.PanelSpecialTool)

    local endTime = self.ViewModel:GetProperty("_ActivityEndTime")
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose or not XDataCenter.Regression3rdManager.IsOpen() then
            XDataCenter.Regression3rdManager.OnActivityEnd()
        end
    end)
end

function XUiRegressionGiftShop:UpdateTime()
    self.TxtTime.text = self.ViewModel:GetLeftTimeDescWithoutPrefix("236778", XUiHelper.TimeFormatType.ACTIVITY)
end 