local XUiDlcMultiPlayerTitleCommon = require(
    "XUi/XUiDlcMultiPlayer/XUiDlcMultiPlayerCommon/XUiDlcMultiPlayerTitleCommon")

---@class XUiDlcMultiPlayerInviteGrid : XUiNode
---@field HeadObject UnityEngine.RectTransform
---@field TxtName UnityEngine.UI.Text
---@field BtnInvite XUiComponent.XUiButton
---@field TxtTips UnityEngine.UI.Text
---@field TxtTime UnityEngine.UI.Text
---@field TitleGrid UnityEngine.UI.Text
---@field _Control XDlcMultiMouseHunterControl
local XUiDlcMultiPlayerInviteGrid = XClass(XUiNode, "XUiDlcMultiPlayerInviteGrid")

-- region 生命周期

function XUiDlcMultiPlayerInviteGrid:OnStart()
    self._Data = nil
    self._TitleGrid = nil
    self:_RegisterButtonClicks()
end

-- endregion

---@param data XDlcMultiplayerFriend
function XUiDlcMultiPlayerInviteGrid:Refresh(data)
    self._Data = data
    self.TxtName.text = data:GetName()
    if data:GetIsWearTitle() then
        if self._TitleGrid then
            self._TitleGrid:Open()
            self._TitleGrid:Refresh(data:GetTitleId())
        else
            self.TitleGrid.gameObject:SetActiveEx(true)
            self._TitleGrid = XUiDlcMultiPlayerTitleCommon.New(self.TitleGrid, self, data:GetTitleId())
        end
    else
        if self._TitleGrid then
            self._TitleGrid:Close()
        else
            self.TitleGrid.gameObject:SetActiveEx(false)
        end
    end

    XUiPlayerHead.InitPortraitWithoutStandIcon(data:GetHeadIconId(), data:GetHeadFrameId(), self.HeadObject)
    if self._Control:CheckPlayerInRoom(data:GetFriendId()) then
        self.BtnInvite.gameObject:SetActiveEx(false)
        self.TxtTips.gameObject:SetActiveEx(true)
        self.TxtTips.text = self._Control:GetInvitedPlayerInTeamStr()
    else
        self:_RefreshInvitedState()
    end
end

function XUiDlcMultiPlayerInviteGrid:SetInvitedTime(time)
    if time > 0 then
        self:_RefreshInvitedTime(time)
    else
        if self._Control:CheckPlayerInRoom(self._Data:GetFriendId()) then
            self.BtnInvite.gameObject:SetActiveEx(false)
            self.TxtTips.gameObject:SetActiveEx(true)
            self.TxtTips.text = self._Control:GetInvitedPlayerInTeamStr()
        else
            self:_RefreshInvitedState()
        end
    end
end

function XUiDlcMultiPlayerInviteGrid:GetData()
    return self._Data
end

-- region 按钮事件

function XUiDlcMultiPlayerInviteGrid:OnBtnInviteClick()
    if XMVCA.XDlcRoom:IsInRoomMatching() then
        XUiManager.TipText("DlcMultiplayerCantInvitedTip")
    else
        if self._Data and self._Data:GetIsOnline() then
            local invitedTime = self._Data:GetInvitedTime()
            local nowTime = XTime.GetServerNowTimestamp()
            local invitedCd = self._Control:GetInvitedTime()

            self.TxtTips.gameObject:SetActiveEx(false)
            self.BtnInvite.gameObject:SetActiveEx(true)

            if invitedTime and nowTime - invitedTime < invitedCd then
                return
            end

            if XMVCA.XDlcRoom:IsInRoom() then
                local team = XMVCA.XDlcRoom:GetTeam()

                if team:IsFull() then
                    XUiManager.TipText("DlcMultiplayerFullInvitedTip")
                    return
                end
            end

            self.Parent:OnInviteClick(self._Data:GetFriendId())
            self._Data:SetInvitedTime(XTime.GetServerNowTimestamp())
            self:_RefreshInvitedState()
        end
    end
end

-- endregion

-- region 私有方法

function XUiDlcMultiPlayerInviteGrid:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    XUiHelper.RegisterClickEvent(self, self.BtnInvite, self.OnBtnInviteClick, true)
end

function XUiDlcMultiPlayerInviteGrid:_RefreshInvitedTime(time)
    self.TxtTime.text = time .. "s"
end

function XUiDlcMultiPlayerInviteGrid:_RefreshInvitedState()
    if self._Data:GetIsOnline() then
        local unlockLevel = self._Control:GetUnlockedLevel()

        if self._Data:GetLevel() >= unlockLevel then
            local invitedTime = self._Data:GetInvitedTime()
            local nowTime = XTime.GetServerNowTimestamp()
            local invitedCd = self._Control:GetInvitedTime()

            self.TxtTips.gameObject:SetActiveEx(false)
            self.BtnInvite.gameObject:SetActiveEx(true)

            if invitedTime and nowTime - invitedTime < invitedCd then
                self.BtnInvite:SetButtonState(CS.UiButtonState.Disable)
                self:_RefreshInvitedTime(invitedCd - nowTime + invitedTime)
            else
                self.BtnInvite:SetButtonState(CS.UiButtonState.Normal)
            end
        else
            self.BtnInvite.gameObject:SetActiveEx(false)
            self.TxtTips.gameObject:SetActiveEx(true)
            self.TxtTips.text = self._Control:GetInviteLockedTipStr(unlockLevel)
        end
    else
        self.BtnInvite.gameObject:SetActiveEx(false)
        self.TxtTips.gameObject:SetActiveEx(true)
        self.TxtTips.text = XUiHelper.GetText("FriendLatelyLogin")
                                .. XUiHelper.CalcLatelyLoginTimeEx(self._Data:GetLastLoginTime())
    end
end

-- endregion

return XUiDlcMultiPlayerInviteGrid
