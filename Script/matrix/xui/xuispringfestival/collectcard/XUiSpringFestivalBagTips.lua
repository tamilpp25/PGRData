local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiSpringFestivalBagTips = XLuaUiManager.Register(XLuaUi, "UiSpringFestivalBagTips")
local XUiGridSpringFestivalBagItem = require("XUi/XUiSpringFestival/CollectCard/XUiGridSpringFestivalBagItem")

function XUiSpringFestivalBagTips:OnStart()
    self:RegisterButtonEvent()
    self:InitDynamicTable()
    self:SetupDynamicTable()
end

function XUiSpringFestivalBagTips:OnGetEvents()
    return {
        XEventId.EVENT_SPRING_FESTIVAL_GIFT_BAG_REFRESH,
    }
end

function XUiSpringFestivalBagTips:OnNotify(event, ...)
    if event == XEventId.EVENT_SPRING_FESTIVAL_GIFT_BAG_REFRESH then
        self:SetupDynamicTable()
    end
end

function XUiSpringFestivalBagTips:RegisterButtonEvent()
    self.BtnTanchuangClose.CallBack = function()
        self:OnClickCloseBtn()
    end
    self.BtnOneReceive.CallBack = function()
        self:OnClickGetRewardBtn()
    end
end

function XUiSpringFestivalBagTips:OnClickGetRewardBtn()
    XDataCenter.SpringFestivalActivityManager.CollectWordsRecvWordGiftFromGiftBoxRequest(function()
        XUiManager.TipText("SpringFestivalGetWordSuccess")
        XEventManager.DispatchEvent(XEventId.EVENT_SPRING_FESTIVAL_GIFT_BAG_RED)
        self:SetupDynamicTable()
    end)
end

function XUiSpringFestivalBagTips:OnClickCloseBtn()
    XLuaUiManager.Close("UiSpringFestivalBagTips")
end

function XUiSpringFestivalBagTips:SetupDynamicTable()
    local dataCount = XDataCenter.SpringFestivalActivityManager.GetGiftCount()
    if self.ImgEmpty then
        self.ImgEmpty.gameObject:SetActiveEx(dataCount == 0)
    end
    self.DynamicTable:SetTotalCount(dataCount)
    self.DynamicTable:ReloadDataASync()
end

function XUiSpringFestivalBagTips:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelContactView)
    self.DynamicTable:SetProxy(XUiGridSpringFestivalBagItem,self)
    self.DynamicTable:SetDelegate(self)
end

function XUiSpringFestivalBagTips:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(index)
    end
end


return XUiSpringFestivalBagTips