local XUiGridSpringFestivalGiveItem = XClass(nil, "XUiGridSpringFestivalGiveItem")

function XUiGridSpringFestivalGiveItem:Ctor(ui)
    self.GameObject = ui
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    if self.BtnHelp then
        self.BtnHelp.CallBack = function()
            self:OnClickBtnHelp()
        end
    end
end

function XUiGridSpringFestivalGiveItem:Refresh(friendInfo,wordId)
    self.WordId = wordId
    self.RequesterId = friendInfo.FriendId

    local name = friendInfo.NickName
    if self.TxtName then
        self.TxtName.text = name
    end

    local isOnline = friendInfo.IsOnline
    if self.TxtOnline then
        self.TxtOnline.gameObject:SetActiveEx(isOnline)
    end
    if self.TxtTime then
        self.TxtTime.gameObject:SetActiveEx(not isOnline)
    end

    if isOnline then
        self.PanelRoleOnLine.gameObject:SetActiveEx(true)
        self.PanelRoleOffLine.gameObject:SetActiveEx(false)
    else
        self.PanelRoleOnLine.gameObject:SetActiveEx(false)
        self.PanelRoleOffLine.gameObject:SetActiveEx(true)
    end

    if isOnline and self.TxtTime then
        self.TxtTime.text = CS.XTextManager.GetText("FriendLatelyLogin") .. XUiHelper.CalcLatelyLoginTime(friendInfo.LastLoginTime)
    end

    local itemName = XDataCenter.ItemManager.GetItemName(self.WordId)
    if self.TxtNewMessage then
        self.TxtNewMessage = CS.XTextManager.GetText("SpringFestivalRequestWordTip", itemName)
    end

    XUiPLayerHead.InitPortrait(friendInfo.Icon, friendInfo.HeadFrameId, self.PanelRoleOnLine)
    XUiPLayerHead.InitPortrait(friendInfo.Icon, friendInfo.HeadFrameId, self.PanelRoleOffLine)
end

function XUiGridSpringFestivalGiveItem:OnClickBtnHelp()
    XDataCenter.SpringFestivalActivityManager.CollectWordsRequestWordToFriendRequest(self.RequesterId, function()
        XUiManager.TipText("SpringFestivalRequestFriendSuccess")
    end)
end

return XUiGridSpringFestivalGiveItem