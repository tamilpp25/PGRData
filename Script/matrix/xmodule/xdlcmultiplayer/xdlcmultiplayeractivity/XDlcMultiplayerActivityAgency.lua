local XDlcActivityAgency = require("XModule/XBase/XDlcActivityAgency")

---@class XDlcMultiplayerActivityAgency : XDlcActivityAgency
local XDlcMultiplayerActivityAgency = XClass(XDlcActivityAgency, "XDlcMultiplayerActivityAgency")

function XDlcMultiplayerActivityAgency:DlcMultiplayerRegisterPrivateConfig(tableName)
    XMVCA.XDlcMultiplayer:RegisterPrivateConfig(self:GetId(), tableName)
end

function XDlcMultiplayerActivityAgency:DlcMultiplayerRegisterAllPrivateConfig()
    self:DlcMultiplayerRegisterPrivateConfig("DlcMultiplayerConfig")
    self:DlcMultiplayerRegisterPrivateConfig("DlcMultiplayerTitleGroup")
    self:DlcMultiplayerRegisterPrivateConfig("DlcMultiplayerTitle")
    self:DlcMultiplayerRegisterPrivateConfig("DlcMultiplayerWorld")
    self:DlcMultiplayerRegisterPrivateConfig("DlcMultiplayerCharacterPool")
end

return XDlcMultiplayerActivityAgency