local XUiBlackGrid = XClass(nil, "XUiBlackGrid")

function XUiBlackGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self.TxtRemark.text = ""
    self:AutoAddListener()
end

function XUiBlackGrid:Init(cb, insertPanelTipsDescCb, isLockRequestRemoveBlacklistFunc)
    self.Cb = cb        --移除被拉黑的玩家成功后的回调方法
    self.InsertPanelTipsDescCb = insertPanelTipsDescCb      --移除被拉黑的玩家成功后插入文本内容的回调方法
    self.IsLockRequestRemoveBlacklistFunc = isLockRequestRemoveBlacklistFunc    --是否正在播放动画中
end

function XUiBlackGrid:AutoAddListener()
    XUiHelper.RegisterClickEvent(self, self.PanelChat, self.OnPanelChatClick)
    XUiHelper.RegisterClickEvent(self, self.BtnView, self.OnBtnViewClick)
end

function XUiBlackGrid:Refresh(playerId, index)
    self.PlayerId = playerId
    self.Index = index

    local data = XDataCenter.SocialManager.GetBlackData(playerId)
    if not data then
        return
    end

    local medalConfig = XMedalConfigs.GetMeadalConfigById(data.CurrMedalId)
    local medalIcon = nil
    if medalConfig then
        medalIcon = medalConfig.MedalIcon
    end
    if medalIcon ~= nil then
        self.MedalRawImage:SetRawImage(medalIcon)
        self.MedalRawImage.gameObject:SetActiveEx(true)
    else
        self.MedalRawImage.gameObject:SetActiveEx(false)
    end

    self.TxtName.text = data.NickName
    if data.Sign == nil or (string.len(data.Sign) == 0) then
        local text = CS.XTextManager.GetText("CharacterSignTip")
        self.TxtNewMessage.text = text
    else
        self.TxtNewMessage.text = data.Sign
    end
    self.TxtTime.text = CS.XTextManager.GetText("FriendLatelyLogin") .. XUiHelper.CalcLatelyLoginTime(data.LastLoginTime)

    XUiPlayerLevel.UpdateLevel(data.Level, self.TxtLevel)

    if data.IsOnline then
        self.TxtOnline.gameObject:SetActiveEx(true)
        self.PanelRoleOffLine.gameObject:SetActiveEx(false)
        self.PanelRoleOnLine.gameObject:SetActiveEx(true)
        self.TxtTime.gameObject:SetActiveEx(false)
    else
        self.TxtOnline.gameObject:SetActiveEx(false)
        self.PanelRoleOffLine.gameObject:SetActiveEx(true)
        self.PanelRoleOnLine.gameObject:SetActiveEx(false)
        self.TxtTime.gameObject:SetActiveEx(true)
    end

    XUiPLayerHead.InitPortrait(data.Icon, data.HeadFrameId, self.PanelRoleOnLine)
    XUiPLayerHead.InitPortrait(data.Icon, data.HeadFrameId, self.PanelRoleOffLine)

    self.CanvasGroup.alpha = 1
    self.Transform.localScale = CS.UnityEngine.Vector3.one

    self:Show()
end

function XUiBlackGrid:Show()
    if self.GameObject:Exist() then
        self.GameObject:SetActiveEx(true)
    end
end

function XUiBlackGrid:OnPanelChatClick()
    if self.IsLockRequestRemoveBlacklistFunc and self.IsLockRequestRemoveBlacklistFunc() then
        return
    end

    local playerId = self:GetPlayerId()
    local cb = function()
        if self.InsertPanelTipsDescCb then
            self.InsertPanelTipsDescCb(CS.XTextManager.GetText("SocialBlackRemoveDesc"))
        end

        local index = self:GetIndex()
        if self.Cb then
            self.Cb(index)
        end
    end
    XDataCenter.SocialManager.RequestRemoveBlacklist(playerId, cb)
end

function XUiBlackGrid:OnBtnViewClick()
    --个人信息
    local playerId = self:GetPlayerId()
    XDataCenter.PersonalInfoManager.ReqShowInfoPanel(playerId)
end

function XUiBlackGrid:GetPlayerId()
    return self.PlayerId
end

function XUiBlackGrid:GetIndex()
    return self.Index
end

function XUiBlackGrid:SetPositionY(positionY)
    if XTool.UObjIsNil(self.Transform) then
        return
    end
    self.Transform.localPosition = CS.UnityEngine.Vector3(self.Transform.localPosition.x, positionY, 0)
end

function XUiBlackGrid:GetPositionY()
    if XTool.UObjIsNil(self.Transform) then
        return
    end
    return self.Transform.localPosition.y
end

function XUiBlackGrid:PlayDisableAnimation()
    self.GridContactDisable.gameObject:SetActiveEx(true)
    self.GridContactDisable:PlayTimelineAnimation(function()
        self.GridContactDisable.gameObject:SetActiveEx(false)
    end)
end

return XUiBlackGrid