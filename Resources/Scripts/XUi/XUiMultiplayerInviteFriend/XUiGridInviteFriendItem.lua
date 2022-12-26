local XUiGridInviteFriendItem = XClass(nil, "XUiGridInviteFriendItem")

function XUiGridInviteFriendItem:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.BtnInvite.CallBack = handler(self, self.OnBtnInviteClick)
end

function XUiGridInviteFriendItem:SetRootUi(parent)
    self.Parent = parent
end

function XUiGridInviteFriendItem:OnBtnInviteClick()
    if not self.Data.IsOnline then
        return
    end
    self.Parent:OnClickInvite(self.Data)
    self.Invited.gameObject:SetActive(true)
    self.BtnInvite.gameObject:SetActive(false)
end

function XUiGridInviteFriendItem:Refresh(data, invited)
    invited = invited or false
    self.Data = data
    self.TxtName.text = XDataCenter.SocialManager.GetPlayerRemark(data.FriendId, data.NickName)

    XUiPlayerLevel.UpdateLevel(data.Level, self.TxtLevel)

    if data.Sign == nil or (string.len(data.Sign) == 0) then
        local text = CS.XTextManager.GetText('CharacterSignTip')
        self.TxtSign.text = text
    else
        self.TxtSign.text = data.Sign
    end

    XDataCenter.PlayerInfoManager.RequestPlayerInfoData(data.FriendId, function (tmpData)
        self.TxtPraiseLevel.text = tmpData.Likes
        if tmpData.FriendInfo then
            self.TxtFetterLevel.text = tmpData.FriendInfo.FetterExp
        else
            self.TxtFetterLevel.text = 1
        end
    end)

    self.Invited.gameObject:SetActive(invited)
    self.BtnInvite.gameObject:SetActive(not invited)
    if data.IsOnline then
        self.TxtOnline.gameObject:SetActive(true)
        self.TxtTime.gameObject:SetActive(false)
        self.HeadOnLine.gameObject:SetActive(true)
        self.HeadOffLine.gameObject:SetActive(false)
        XUiPLayerHead.InitPortrait(data.Icon, data.HeadFrameId, self.HeadOnLine)
        self.BtnInvite.ButtonState = CS.UiButtonState.Normal
    else
        self.TxtOnline.gameObject:SetActive(false)
        local loginText = CS.XTextManager.GetText("FriendLatelyLogin")
        self.TxtTime.text = loginText .. XUiHelper.CalcLatelyLoginTime(data.LastLoginTime)
        self.TxtTime.gameObject:SetActive(true)
        self.HeadOnLine.gameObject:SetActive(false)
        self.HeadOffLine.gameObject:SetActive(true)
        XUiPLayerHead.InitPortrait(data.Icon, data.HeadFrameId, self.HeadOffLine)
        self.BtnInvite.ButtonState = CS.UiButtonState.Disable
    end
end

return XUiGridInviteFriendItem