local XUiSpringFestivalFriendTip = XLuaUiManager.Register(XLuaUi,"UiSpringFestivalFriendTip")
local XUiGridSpringFestivalGiveFriend = require("XUi/XUiSpringFestival/CollectCard/XUiGridSpringFestivalGiveFriend")

function XUiSpringFestivalFriendTip:OnStart(wordId)
   self.WordId = wordId 
end

function XUiSpringFestivalFriendTip:OnEnable()
    self:RegisterButtonEvent()
    XDataCenter.SpringFestivalActivityManager.CollectWordsRefreshRequestWordListRequest(function()
        self:InitDynamicTable()
        self:SetupDynamicTable()
    end)
end

function XUiSpringFestivalFriendTip:RegisterButtonEvent()
    self.BtnTanchuangClose.CallBack = function()
        self.OnClickBackBtn()
    end
end

function XUiSpringFestivalFriendTip:OnClickBackBtn()
    XLuaUiManager.Close("UiSpringFestivalFriendTip")
end

function XUiSpringFestivalFriendTip:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelFriendList)
    self.DynamicTable:SetProxy(XUiGridSpringFestivalGiveFriend)
    self.DynamicTable:SetDelegate(self)
end

function XUiSpringFestivalFriendTip:SetupDynamicTable()
    self.FriendList = XDataCenter.SocialManager.GetFriendList()
    self.ImgEmpty.gameObject:SetActiveEx(#self.FriendList == 0)
    self.DynamicTable:SetTotalCount(#self.FriendList)
    self.DynamicTable:ReloadDataASync()
end

function XUiSpringFestivalFriendTip:OnDynamicTableEvent(event,index,grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.FriendList[index],self.WordId)
    end
end


return XUiSpringFestivalFriendTip