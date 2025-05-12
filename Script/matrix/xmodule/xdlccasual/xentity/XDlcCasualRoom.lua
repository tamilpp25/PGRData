local XDlcRoom = require("XModule/XDlcRoom/XEntity/XDlcRoom")
---@class XDlcCasualRoom : XDlcRoom
local XDlcCasualRoom = XClass(XDlcRoom, "XDlcCasualRoom")

function XDlcCasualRoom:GetTutorialNpcId()
    local characterId = self:GetFightCharacterId()
    ---@type XDlcCasualAgency
    local agency = XMVCA:GetAgency(ModuleId.XDlcCasual)

    return agency:GetNpcIdById(characterId)
end

function XDlcCasualRoom:OpenMultiplayerRoom()
    XLuaUiManager.Open("UiDlcCasualplayerRoomCute")
end

function XDlcCasualRoom:PopThenOpenMultiplayerRoom()
    XLuaUiManager.PopThenOpen("UiDlcCasualplayerRoomCute")
end

function XDlcCasualRoom:OpenFightUiLoading()
    XLuaUiManager.Open("UiDlcCasualGameLoading")
end

function XDlcCasualRoom:CloseFightUiLoading()
    XLuaUiManager.Close("UiDlcCasualGameLoading")
end

function XDlcCasualRoom:OnDisconnect()
    XLuaUiManager.Open("UiDlcSettleLose")
    XLuaUiManager.SafeClose("UiDlcCasualplayerRoomCute")
end

function XDlcCasualRoom:OnTutorialFightFinish()
    XLuaUiManager.SafeClose("UiDlcCasualplayerRoomCute")
end

function XDlcCasualRoom:OnRoomLeaderTimeOut()
    if not XUiManager.CheckTopUi(CsXUiType.Normal, "UiDlcCasualplayerRoomCute") then
        XLuaUiManager.Remove("UiDlcCasualplayerRoomCute")
    end
end

function XDlcCasualRoom:OnKickOut(code)
    XLuaUiManager.SafeClose("UiDialog")
    XLuaUiManager.SafeClose("UiReport")
    XLuaUiManager.SafeClose("UiRoomCharacter")
    XLuaUiManager.SafeClose("UiPlayerInfo")
    XLuaUiManager.SafeClose("UiChatServeMain")
    XLuaUiManager.SafeClose("UiDlcCasualGamesRoomExchange")

    if not XUiManager.CheckTopUi(CsXUiType.Normal, "UiDlcCasualplayerRoomCute") then
        XLuaUiManager.Remove("UiDlcCasualplayerRoomCute")
    end
end

function XDlcCasualRoom:OnCreateRoom()
    XLuaUiManager.SafeClose("UiDialog")
    XLuaUiManager.SafeClose("UiHelp")
end

function XDlcCasualRoom:OnEnterWorld()
    XLuaUiManager.SafeClose("UiDialog")
    XLuaUiManager.SafeClose("UiMultiplayerInviteFriend")
    XLuaUiManager.SafeClose("UiPlayerInfo")
    XLuaUiManager.SafeClose("UiChatServeMain")
    XLuaUiManager.SafeClose("UiGuildRankingList")
end

return XDlcCasualRoom
