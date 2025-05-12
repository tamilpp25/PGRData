local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiBigListGrid = require("XUi/XUiNewRegression/Discount/XUiBigListGrid")

local tableInsert = table.insert
local tableSort = table.sort

--回归礼包界面
local XUiPanelDiscount = XClass(XSignalData, "XUiPanelDiscount")

function XUiPanelDiscount:Ctor(ui, rootUi)
    XUiHelper.InitUiClass(self, ui)
    self.RootUi = rootUi
    self:InitPurchaseList()
    self:InitPanelItemList()
    self:InitTxtTitle()
end

function XUiPanelDiscount:InitTxtTitle()
    if not self.TxtTitle then
        return
    end
    local days = XDataCenter.NewRegressionManager.GetActivityContinueDays()
    self.TxtTitle.text = XUiHelper.GetText("NewRegressDiscountTitle", days)
end

function XUiPanelDiscount:InitPanelItemList()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelItemList)
    self.DynamicTable:SetProxy(XUiBigListGrid)
    self.DynamicTable:SetDelegate(self)
    self.PanelBigList.gameObject:SetActiveEx(false)
end

function XUiPanelDiscount:InitPurchaseList()
    local uiType = XNewRegressionConfigs.GetChildActivityConfig("DiscountUiType")
    uiType = uiType and tonumber(uiType)
    if uiType then
        self.UiType = uiType
        XDataCenter.PurchaseManager.GetPurchaseListRequest({uiType}, function()
            self:RefreshPanelItemList()
        end)
    end
end

function XUiPanelDiscount:SetData(manager)
    self.DiscountManager = manager
    self:RefreshPanelItemList()
    self:RefreshLeaveTime()

    manager:SaveClickCookie()
    self:EmitSignal("RefreshRedPoint")
end

function XUiPanelDiscount:UpdateWithSecond()
    self:RefreshLeaveTime()
end

-- 刷新倒计时
function XUiPanelDiscount:RefreshLeaveTime()
    self.TxtTime.text = XUiHelper.GetText("NewRegressChildActivityLeftTime", XDataCenter.NewRegressionManager.GetLeaveTimeStr())
end

function XUiPanelDiscount:RefreshPanelItemList()
    local uiType = self.UiType
    if not uiType then
        return
    end

    local purcheseDatas = XDataCenter.PurchaseManager.GetDatasByUiType(uiType) or {}
    self:OnSortFun(purcheseDatas)
    self.DynamicTable:SetDataSource(self.ListData)
    self.DynamicTable:ReloadDataASync()

    self.PanelEmpty.gameObject:SetActiveEx(XTool.IsTableEmpty(self.ListData))
end

-- 先分类后排序
function XUiPanelDiscount:OnSortFun(data)
    local sellOutList = {}--买完了
    local sellingList = {}--在上架中
    self.ListData = {}

    for _,v in pairs(data)do
        if v and not v.IsSelloutHide then
            if v.BuyTimes > 0 and v.BuyLimitTimes > 0 and v.BuyTimes >= v.BuyLimitTimes then--买完了
                tableInsert(sellOutList, v)
            else                                                       --在上架中,还能买。
                tableInsert(sellingList, v)
            end
        end
    end

    --在上架中,还能买。
    if next(sellingList) then
        tableSort(sellingList, XUiPanelDiscount.SortByPriority)
        for _,v in pairs(sellingList) do
            tableInsert(self.ListData, v)
        end
    end

    --买完了
    if next(sellOutList) then
        tableSort(sellOutList, XUiPanelDiscount.SortByPriority)
        for _,v in pairs(sellOutList) do
            tableInsert(self.ListData, v)
        end
    end
end

function XUiPanelDiscount.SortByPriority(a,b)
    return a.Priority < b.Priority
end

function XUiPanelDiscount:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self.RootUi, handler(self, self.RefreshPanelItemList))
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.ListData[index])
    end
end

return XUiPanelDiscount