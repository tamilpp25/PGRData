local XUiGridSpringFestivalBagItem = XClass(nil, "XUiGridSpringFestivalBagItem")

function XUiGridSpringFestivalBagItem:Ctor(ui,parent)
    self.GameObject = ui
    self.Transform = ui.transform
    self.Parent = parent
    XTool.InitUiObject(self)
end

function XUiGridSpringFestivalBagItem:RegisterButtonEvent()
    self.BtnReceive.CallBack = function()
        self:OnClickReceive()
    end
end

function XUiGridSpringFestivalBagItem:Refresh(index)
        self.DataInfo = XDataCenter.SpringFestivalActivityManager.GetGiftBoxDataByIndex(index)
        self:RefreshPlayerInfo()
end

function XUiGridSpringFestivalBagItem:RefreshPlayerInfo()
        self.TxtLevel.text = self.DataInfo:GetFriendLevel()
        self.TxtName.text = self.DataInfo:GetSenderName()
        self.TxtRemark.text = self.DataInfo:GetFriendRemark()
        self.TxtTime.text = CS.XTextManager.GetText("FriendLatelyLogin") .. XUiHelper.CalcLatelyLoginTime(self.DataInfo:GetFriendLastLoginTime())
        local isOnline = self.DataInfo:IsFriendOnline()
        if isOnline then
            self.PanelRoleOffLine.gameObject:SetActive(false)
            self.PanelRoleOnLine.gameObject:SetActive(true)
            self.TxtTime.gameObject:SetActive(false)
            self.TxtOnline.gameObject:SetActive(false)
        else
            self.PanelRoleOffLine.gameObject:SetActive(true)
            self.PanelRoleOnLine.gameObject:SetActive(false)
        self.TxtTime.gameObject:SetActive(true)
        self.TxtOnline.gameObject:SetActive(false)
    end
    self.GiftGrid = XUiGridCommon.New(self.Parent,self.GridCommon)
    local itemData = XDataCenter.ItemManager.GetItemTemplate(self.DataInfo:GetWordId())
    if itemData then
        self.GiftGrid:Refresh(itemData)
    end

    if self.TxtNewMessage then
        local message = CS.XTextManager.GetText("SpringFestivalSendWordMessage",XDataCenter.ItemManager.GetItemName(self.DataInfo:GetWordId()))
        self.TxtNewMessage.text = message
    end
    self.GridReceived.gameObject:SetActiveEx(self.DataInfo:IsReceive())
    XUiPLayerHead.InitPortrait(self.DataInfo:GetFriendIcon(), self.DataInfo:GetFriendHeadFrameId(), self.PanelRoleOnLine)
    XUiPLayerHead.InitPortrait(self.DataInfo:GetFriendIcon(), self.DataInfo:GetFriendHeadFrameId(), self.PanelRoleOffLine)
end

return XUiGridSpringFestivalBagItem