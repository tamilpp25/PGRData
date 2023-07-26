local XUiSpringFestivalGiveTips = XLuaUiManager.Register(XLuaUi, "UiSpringFestivalGiveTips")
local XUiGridSpringFestivalFriend = require("XUi/XUiSpringFestival/CollectCard/XUiGridSpringFestivalFriend")

function XUiSpringFestivalGiveTips:OnStart()

end

function XUiSpringFestivalGiveTips:OnEnable()
    self:RegisterButtonEvent()
    self:InitDynamicTable()
    XDataCenter.SpringFestivalActivityManager.CollectWordsRefreshRequestWordListRequest(function()
        self:SetupDynamicTable()
    end)
end

function XUiSpringFestivalGiveTips:OnDisable()

end

function XUiSpringFestivalGiveTips:OnDestroy()

end

function XUiSpringFestivalGiveTips:RegisterButtonEvent()
    self.BtnTanchuangClose.CallBack = function()
        self:OnClickCloseBtn()
    end
end

function XUiSpringFestivalGiveTips:OnClickCloseBtn()
    XLuaUiManager.Close("UiSpringFestivalGiveTips")
end

function XUiSpringFestivalGiveTips:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelFriendList)
    self.DynamicTable:SetProxy(XUiGridSpringFestivalFriend)
    self.DynamicTable:SetDelegate(self)
end

function XUiSpringFestivalGiveTips:SetupDynamicTable()
    self.RequestList = XDataCenter.SpringFestivalActivityManager.GetFriendRequestList()
    if self.ImgEmpty then
        self.ImgEmpty.gameObject:SetActiveEx(#self.RequestList == 0)
    end
    self.DynamicTable:SetTotalCount(#self.RequestList)
    self.DynamicTable:ReloadDataASync()
end

function XUiSpringFestivalGiveTips:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.RequestList[index])
    end
end

return XUiSpringFestivalGiveTips