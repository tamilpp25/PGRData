local XDlcRoom = require("XModule/XDlcRoom/XEntity/XDlcRoom")
---@class XDlcCasualRoom : XDlcRoom
local XDlcCasualRoom = XClass(XDlcRoom, "XDlcCasualRoom")

function XDlcCasualRoom:GetTutorialNpcId()
    local characterId = self:GetFightCharacterId()
    ---@type XDlcCasualAgency
    local agency = XMVCA:GetAgency(ModuleId.XDlcCasual)

    return agency:GetNpcIdById(characterId)
end

function XDlcRoom:OpenMultiplayerRoom()
    XLuaUiManager.Open("UiDlcCasualplayerRoomCute")
end

function XDlcRoom:OpenFightLoading()
    XLuaUiManager.Open("UiDlcCasualGameLoading")
end

function XDlcCasualRoom:CloseFightLoading()
    XLuaUiManager.SafeClose("UiDlcCasualGameLoading")
end

function XDlcCasualRoom:OnDisconnect()
    XLuaUiManager.Open("UiSettleLose")
    XLuaUiManager.SafeClose("UiDlcCasualplayerRoomCute")
end

function XDlcCasualRoom:OnTutorialFightFinish()
    XLuaUiManager.SafeClose("UiDlcCasualplayerRoomCute")
end

return XDlcCasualRoom
