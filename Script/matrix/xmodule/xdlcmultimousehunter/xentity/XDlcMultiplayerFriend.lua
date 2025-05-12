---@class XDlcMultiplayerFriend
local XDlcMultiplayerFriend = XClass(nil, "XDlcMultiplayerFriend")

function XDlcMultiplayerFriend:Ctor(data)
    self:SetData(data)
end

function XDlcMultiplayerFriend:SetData(data)
    if data then
        self._Level = data.Level
        self._Name = data.Name
        self._HeadIconId = data.CurrHeadPortraitId
        self._HeadFrameId = data.CurrHeadFrameId
        self._FriendId = data.Id
        self._IsOnline = data.IsOnline
        self._TitleId = data.DlcMultiplayerTitle
        self._LastLoginTime = data.LastLoginTime
        self._InvitedTime = self._InvitedTime or 0
    end
end

function XDlcMultiplayerFriend:GetLevel()
    return self._Level
end

function XDlcMultiplayerFriend:GetName()
    return self._Name
end

function XDlcMultiplayerFriend:GetFriendId()
    return self._FriendId
end

function XDlcMultiplayerFriend:GetIsOnline()
    return self._IsOnline
end

function XDlcMultiplayerFriend:GetIsWearTitle()
    return XTool.IsNumberValid(self:GetTitleId())
end

function XDlcMultiplayerFriend:GetTitleId()
    return self._TitleId
end

function XDlcMultiplayerFriend:GetTitleIcon()
    if self:GetIsWearTitle() then
        return XMVCA.XDlcMultiMouseHunter:GetTitleIcon(self:GetTitleId())
    end

    return ""
end

function XDlcMultiplayerFriend:GetTitleBackground()
    if self:GetIsWearTitle() then
        return XMVCA.XDlcMultiMouseHunter:GetTitleBackground(self:GetTitleId())
    end

    return ""
end

function XDlcMultiplayerFriend:GetTitleContent()
    if self:GetIsWearTitle() then
        return XMVCA.XDlcMultiMouseHunter:GetTitleContent(self:GetTitleId())
    end

    return ""
end

function XDlcMultiplayerFriend:GetLastLoginTime()
    return self._LastLoginTime
end

function XDlcMultiplayerFriend:SetInvitedTime(value)
    self._InvitedTime = value
end

function XDlcMultiplayerFriend:GetInvitedTime()
    return self._InvitedTime
end

function XDlcMultiplayerFriend:GetHeadIconId()
    return self._HeadIconId
end

function XDlcMultiplayerFriend:GetHeadFrameId()
    return self._HeadFrameId
end

return XDlcMultiplayerFriend
