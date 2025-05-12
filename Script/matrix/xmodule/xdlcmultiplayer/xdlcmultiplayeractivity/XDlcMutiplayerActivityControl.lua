---@class XDlcMutiplayerActivityControl : XControl
local XDlcMutiplayerActivityControl = XClass(XControl, "XDlcMutiplayerActivityControl")

function XDlcMutiplayerActivityControl:OnInit()
    self:OnStart()
    self:LoadActivityPrivateConfig()
end

function XDlcMutiplayerActivityControl:OnStart()
    XLog.Error("Dlc多人玩法活动需要重写OnStart而不是OnInit方法")
end

function XDlcMutiplayerActivityControl:OnDestroy()
    XLog.Error("Dlc多人玩法活动需要重写OnDestroy而不是OnRelease方法")
end

function XDlcMutiplayerActivityControl:OnRelease()
    self:ClearActivityPrivateConfig()
    self:OnDestroy()
end

function XDlcMutiplayerActivityControl:LoadActivityPrivateConfig()
    XMVCA.XDlcMultiplayer:LoadPrivateConfig(self:GetId())
end

function XDlcMutiplayerActivityControl:ClearActivityPrivateConfig()
    XMVCA.XDlcMultiplayer:ClearPrivateConfig(self:GetId())
end

return XDlcMutiplayerActivityControl