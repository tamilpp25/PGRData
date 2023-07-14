local XUiSpecialFashionShop = XLuaUiManager.Register(XLuaUi, "UiSpecialFashionShop")

local XUiCommodityLine = require("XUi/XUiSpecialFashionShop/XUiGridCommodityLine")
local Dropdown = CS.UnityEngine.UI.Dropdown
local CurrentSchedule

function XUiSpecialFashionShop:OnAwake()
    self.TimerFunctions = {}

    self:InitComponent()
    self:AddListener()
end

function XUiSpecialFashionShop:OnStart(shopId)
    self.ShopId = shopId
    self.ScreenGroupIDList = {}

    -- 初始化筛选标签
    self:InitScreen(self.ShopId)
    self:InitDropFilter()
end

function XUiSpecialFashionShop:OnEnable()
    self:Refresh()
end

function XUiSpecialFashionShop:OnDisable()
    if self.FashionScrollRect then
        self.AnchoredPosition = self.FashionScrollRect.content.anchoredPosition
    end
end

function XUiSpecialFashionShop:OnDestroy()
    self:DestroyTimer()
end

function XUiSpecialFashionShop:Refresh()
    -- 货币
    self.AssetActivityPanel:Refresh(XShopManager.GetShopShowIdList(self.ShopId))

    -- 活动时间
    local startTime, endTime = XSpecialShopConfigs.GetDurationTimeStamp()
    local nowTime = XTime.GetServerNowTimestamp()
    self.TxtTime.text = XUiHelper.GetTime(endTime - nowTime, XUiHelper.TimeFormatType.ACTIVITY)

    -- 商品数据，筛选标签为全部则需要区分系列
    local isSeries = self.DropFilter.value == 0
    self.CommodityLineData = XDataCenter.SpecialShopManager.GetCommodityLineData(self.ShopId, self.ScreenGroupIDList[self.ScreenNum], self.SelectTag, isSeries)
    self.DynamicTable:SetDataSource(self.CommodityLineData)
    self.DynamicTable:ReloadDataASync()

    if next(self.CommodityLineData) then
        self.TxtEmptyDesc.gameObject:SetActiveEx(false)
    else
        self.TxtEmptyDesc.gameObject:SetActiveEx(true)
        self.TxtHint.text = CS.XTextManager.GetText("ShopNoGoodsDesc")
    end
end

function XUiSpecialFashionShop:InitComponent()
    self.GridCommodityLine.gameObject:SetActiveEx(false)
    self.TxtEmptyDesc.gameObject:SetActiveEx(false)
    self.BtnSearch.gameObject:SetActiveEx(false)

    self:StartTimer()
    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool)

    self.DynamicTable = XDynamicTableNormal.New(self.PanelFashionList)
    self.DynamicTable:SetProxy(XUiCommodityLine)
    self.DynamicTable:SetDelegate(self)
    self.FashionScrollRect = self.PanelFashionList:GetComponent("ScrollRect")
end

function XUiSpecialFashionShop:StartTimer()
    if self.IsStart then
        return
    end

    self.IsStart = true
    CurrentSchedule = XScheduleManager.ScheduleForever(function()
        self:UpdateTimer()
    end, 1000)
end

function XUiSpecialFashionShop:UpdateTimer()
    if next(self.TimerFunctions) then
        for _, timerFun in pairs(self.TimerFunctions) do
            if timerFun then
                timerFun()
            end
        end
    end
end

function XUiSpecialFashionShop:RegisterTimerFun(id, fun)
    self.TimerFunctions[id] = fun
end

function XUiSpecialFashionShop:RemoveTimerFun(id)
    self.TimerFunctions[id] = nil
end

function XUiSpecialFashionShop:DestroyTimer()
    if CurrentSchedule then
        self.IsStart = false
        XScheduleManager.UnSchedule(CurrentSchedule)
        CurrentSchedule = nil
    end
end

function XUiSpecialFashionShop:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.CommodityLineData[index]
        grid:Refresh(data)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RECYCLE then
        grid:OnRecycle()
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        if self.AnchoredPosition then
            self.FashionScrollRect.content.anchoredPosition = self.AnchoredPosition
        end
    end
end

function XUiSpecialFashionShop:GetProxyType()
    return "XUiCommodityLine"
end

function XUiSpecialFashionShop:GetCurShopId()
    return self.ShopId
end

function XUiSpecialFashionShop:RefreshBuy()
    self:Refresh()
end

function XUiSpecialFashionShop:InitScreen(shopId)
    self.ScreenGroupIDList = XShopManager.GetShopScreenGroupIDList(shopId)
    if self.ScreenGroupIDList and #self.ScreenGroupIDList > 0 then
        self.IsHasScreen = true
        self.ScreenNum = 1
    else
        self.IsHasScreen = false
    end

    self.DropFilter.gameObject:SetActiveEx(self.IsHasScreen)
end

function XUiSpecialFashionShop:InitDropFilter()
    self.ScreenTagList = XShopManager.GetScreenTagListById(self.ShopId,self.ScreenGroupIDList[self.ScreenNum])

    self.DropFilter:ClearOptions()
    self.DropFilter.captionText.text = CS.XTextManager.GetText("ScreenAll")

    for _,v in pairs(self.ScreenTagList or {}) do
        local op = Dropdown.OptionData()
        op.text = v.Text
        self.DropFilter.options:Add(op)
    end
    self.DropFilter.value = 0
    self.SelectTag = self.DropFilter.captionText.text
end


---------------------------------------------------添加监听函数---------------------------------------------------------

function XUiSpecialFashionShop:AddListener()
    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end
    self.BtnMainUi.CallBack = function()
        self:OnBtnMainUiClick()
    end
    self.DropFilter.onValueChanged:AddListener(function()
        self.SelectTag = self.DropFilter.captionText.text
        self:Refresh()
    end)
end

function XUiSpecialFashionShop:OnBtnBackClick()
    self:Close()
end

function XUiSpecialFashionShop:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end