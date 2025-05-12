local XUiGridSpringFestivalGiveFriend = XClass(nil, "XUiGridSpringFestivalGiveFriend")

function XUiGridSpringFestivalGiveFriend:Ctor(ui)
    self.GameObject = ui
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    if self.BtnGive then
        self.BtnGive.CallBack = function()
            self:OnClickBtnGive()
        end
    end
end

function XUiGridSpringFestivalGiveFriend:Refresh(friendInfo, wordId)
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
        self.TxtNewMessage.text = CS.XTextManager.GetText("SpringFestivalSendWordTip", itemName)
    end

    XUiPlayerHead.InitPortrait(friendInfo.Icon, friendInfo.HeadFrameId, self.PanelRoleOnLine)
    XUiPlayerHead.InitPortrait(friendInfo.Icon, friendInfo.HeadFrameId, self.PanelRoleOffLine)
end

function XUiGridSpringFestivalGiveFriend:OnClickBtnGive()
        XDataCenter.SpringFestivalActivityManager.CollectWordsGiveWordToOthersRequest(self.WordId, self.RequesterId,false, function(rewards)
            XUiManager.TipText("SpringFestivalSendWordSuccess")
            if not rewards then
                return
            end
            XUiManager.OpenUiTipReward(rewards)
        end)
end

return XUiGridSpringFestivalGiveFriend