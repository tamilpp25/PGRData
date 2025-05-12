local XUiDlcInvitationPopupBase = require("XUi/XUiDlcBase/XUiDlcInvitationPopupBase")

---@class XUiDlcMultiPlayerInvitationPopup : XUiDlcInvitationPopupBase
---@field TxtName UnityEngine.UI.Text
---@field TxtChpaterName UnityEngine.UI.Text
---@field BtnSure XUiComponent.XUiButton
---@field BtnCancel XUiComponent.XUiButton
local XUiDlcMultiPlayerInvitationPopup = XLuaUiManager.Register(XUiDlcInvitationPopupBase,
    "UiDlcMultiPlayerInvitationPopup")

-- region 生命周期

function XUiDlcMultiPlayerInvitationPopup:OnAwake()
    self._InviteData = nil

    self:_RegisterButtonClicks()
end

function XUiDlcMultiPlayerInvitationPopup:OnStart(inviteData)
    self._InviteData = inviteData

    self:_Refresh()
    self:RegisterAutoClose()
end

-- endregion

function XUiDlcMultiPlayerInvitationPopup:SetPanelActive(isActive)
    self.PanelInvite.gameObject:SetActiveEx(isActive)
end

-- region 按钮事件

function XUiDlcMultiPlayerInvitationPopup:OnBtnSureClick()
    local content = self._InviteData.Content

    if content then
        local params = string.Split(content, "|")

        if params then
            local worldId = tonumber(params[3])
            local roomId = params[4]
            local nodeId = params[7]

            XMVCA.XDlcRoom:ClickEnterRoomHref(roomId, nodeId, worldId, self._InviteData.CreateTime)
        end
    end

    self:_CloseAndReadMessage()
end

function XUiDlcMultiPlayerInvitationPopup:OnBtnCancelClick()
    self:_CloseAndReadMessage()
end

-- endregion

-- region 私有方法

function XUiDlcMultiPlayerInvitationPopup:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    self:RegisterClickEvent(self.BtnSure, self.OnBtnSureClick, true)
    self:RegisterClickEvent(self.BtnCancel, self.OnBtnCancelClick, true)
end

function XUiDlcMultiPlayerInvitationPopup:_Refresh()
    local content = self._InviteData.Content

    if content then
        self.TxtChpaterName.text = XMVCA.XDlcMultiMouseHunter:ExGetName()
        self.TxtName.text = self._InviteData.NickName
        self:CheckShowPanel()
    else
        self:Close()
    end
end

function XUiDlcMultiPlayerInvitationPopup:_CloseAndReadMessage()
    if self._InviteData then
        XDataCenter.ChatManager.SetPrivateChatReadByFriendIdAndMessageId(self._InviteData.SenderId,
        self._InviteData.MessageId)
    end
    self:Close()
end

-- endregion

return XUiDlcMultiPlayerInvitationPopup
