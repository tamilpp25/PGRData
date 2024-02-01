local XUiConsumeActivityShop = XLuaUiManager.Register(XLuaUi,"UiConsumeActivityShop")
local XUiGridConsumeActivityShop = require("XUi/XUiAccumulatedConsume/XUiGridConsumeActivityShop")

function XUiConsumeActivityShop:OnAwake()
    self:RegisterUiEvents()
    self.PanelBigList.gameObject:SetActiveEx(false)
    self.TxtTime.gameObject:SetActiveEx(false)
end

function XUiConsumeActivityShop:OnStart()
    ---@type ConsumeDrawActivityEntity
    self.ConsumeDrawActivity = XDataCenter.AccumulatedConsumeManager.GetConsumeDrawActivity()
    self.AssetPanel = XUiHelper.NewPanelActivityAssetSafe({ self.ConsumeDrawActivity:GetShopCoinItemId() }, self.PanelSpecialTool, self)
    
    self:InitDynamicTable()
    self.ShopId = self.ConsumeDrawActivity:GetShopId()
end

function XUiConsumeActivityShop:OnEnable()
    XShopManager.ClearBaseInfoData()
    XShopManager.GetBaseInfo(function()
        self:UpdateTog()
    end)
end

function XUiConsumeActivityShop:OnDisable()
    self:RemoveTimer()
end

function XUiConsumeActivityShop:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelItemList)
    self.DynamicTable:SetProxy(XUiGridConsumeActivityShop)
    self.DynamicTable:SetDelegate(self)
end

function XUiConsumeActivityShop:UpdateDynamicTable()
    self.ShopGoods = XShopManager.GetShopGoodsList(self.ShopId)
    self.DynamicTable:SetDataSource(self.ShopGoods)
    self.DynamicTable:ReloadDataASync(1)
end

function XUiConsumeActivityShop:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.ShopGoods[index])
    end
end

function XUiConsumeActivityShop:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, self.OnBtnMainUiClick)
    self:BindHelpBtn(self.BtnHelp, "ConsumeActivityShop")
end

function XUiConsumeActivityShop:UpdateTog()
    XShopManager.GetShopInfo(self.ShopId, function()
        self:UpdateDynamicTable()
        self:RefreshTime()
    end)
end

function XUiConsumeActivityShop:RefreshTime()
    if self.Timer then
        self:RemoveTimer()
    end
    -- 活动时间
    local timeInfo = XShopManager.GetShopTimeInfo(self.ShopId)
    if XTool.IsTableEmpty(timeInfo) then
        return
    end

    local refreshFunc

    local leftTime = timeInfo.ClosedLeftTime
    if leftTime and leftTime > 0 then
        refreshFunc = function()
            local timeStr = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
            self.TxtTime.text = CSXTextManagerGetText("ConsumeActivityShopTime", timeStr)

            leftTime = leftTime - 1

            if leftTime < 0 then
                refreshFunc = nil
            end
        end
    end

    if refreshFunc then
        refreshFunc()
        self.TxtTime.gameObject:SetActiveEx(true)
    end

    self.Timer = XScheduleManager.ScheduleForever(function()
        if not refreshFunc then
            self:RemoveTimer()
            XDataCenter.AccumulatedConsumeManager.HandleActivityEndTime()
            return
        end

        if refreshFunc then
            refreshFunc()
        end
    end, 1000)
end

function XUiConsumeActivityShop:RemoveTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiConsumeActivityShop:UpdateBuy(data, cb)
    XLuaUiManager.Open("UiShopItem",self,data, cb)
end

function XUiConsumeActivityShop:GetCurShopId()
    return self.ShopId
end
-- 购买后刷新
function XUiConsumeActivityShop:RefreshBuy()

end

function XUiConsumeActivityShop:OnBtnBackClick()
    self:Close()
end

function XUiConsumeActivityShop:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

return XUiConsumeActivityShop