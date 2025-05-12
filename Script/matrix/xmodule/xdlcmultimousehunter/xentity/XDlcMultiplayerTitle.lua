---@class XDlcMultiplayerTitle
local XDlcMultiplayerTitle = XClass(nil, "XDlcMultiplayerTitle")

function XDlcMultiplayerTitle:Ctor(config, info)
    self:SetData(config)
    self:SetInfo(info)
end

function XDlcMultiplayerTitle:SetData(config)
    if config then
        self._Config = config
        self._UnlockTime = 0
        self._Progress = 0
        self._IsUnlock = false
        self._IsWear = false
        self._IsFirstUnlock = false
    end
end

function XDlcMultiplayerTitle:SetInfo(info, isWear)
    if info then
        self._IsUnlock = true
        self._IsWear = isWear or false
        self._IsFirstUnlock = XMVCA.XDlcMultiMouseHunter:GetIsFirstUnlockTitle(self:GetId())
        self._UnlockTime = XTime.TimestampToGameDateTimeString(info.UnlockTime)
    end
end

function XDlcMultiplayerTitle:SetProgress(progress)
    self._Progress = progress
end

function XDlcMultiplayerTitle:GetId()
    return self._Config and self._Config.Id or 0
end

function XDlcMultiplayerTitle:GetContent()
    return self._Config and self._Config.TitleContent or ""
end

function XDlcMultiplayerTitle:GetBackground()
    return self._Config and self._Config.Background or ""
end

function XDlcMultiplayerTitle:GetIcon()
    return self._Config and self._Config.Icon or ""
end

function XDlcMultiplayerTitle:GetDesc()
    return self._Config and self._Config.Desc or ""
end

function XDlcMultiplayerTitle:GetIsProgress()
    return self._Config and self._Config.IsProgress or false
end

function XDlcMultiplayerTitle:GetUnlockTime()
    return self._UnlockTime or 0
end

function XDlcMultiplayerTitle:GetIsUnlock()
    return self._IsUnlock
end

function XDlcMultiplayerTitle:GetIsWear()
    return self._IsWear
end

function XDlcMultiplayerTitle:GetIsFirstUnlock()
    return self._IsFirstUnlock
end

function XDlcMultiplayerTitle:GetProgress()
    return self._Progress
end

function XDlcMultiplayerTitle:ChangeFirstUnlock()
    if self._IsFirstUnlock then
        self._IsFirstUnlock = false
        XMVCA.XDlcMultiMouseHunter:SetIsFirstUnlockTitle(self:GetId())
    end
end

function XDlcMultiplayerTitle:Wear()
    self._IsWear = true
end

function XDlcMultiplayerTitle:UnWear()
    self._IsWear = false
end

return XDlcMultiplayerTitle