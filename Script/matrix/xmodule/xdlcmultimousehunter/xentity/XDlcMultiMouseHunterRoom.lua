local XDlcRoom = require("XModule/XDlcRoom/XEntity/XDlcRoom")

---@class XDlcMultiMouseHunterRoom : XDlcRoom
local XDlcMultiMouseHunterRoom = XClass(XDlcRoom, "XDlcMultiMouseHunterRoom")

function XDlcMultiMouseHunterRoom:OpenMultiplayerRoom()
    XLuaUiManager.Open("UiDlcMultiPlayerRoomCute")
end

function XDlcMultiMouseHunterRoom:PopThenOpenMultiplayerRoom()
    XLuaUiManager.PopThenOpen("UiDlcMultiPlayerRoomCute")
end

function XDlcMultiMouseHunterRoom:OpenFightUiLoading()
    XLuaUiManager.Open("UiDlcMultiPlayerLoading")
end

function XDlcMultiMouseHunterRoom:CloseFightUiLoading()
    XLuaUiManager.Close("UiDlcMultiPlayerLoading")
end

function XDlcMultiMouseHunterRoom:OnDisconnect()
    XLuaUiManager.Open("UiDlcSettleLose")
    XLuaUiManager.SafeClose("UiDlcMultiPlayerRoomCute")
end

function XDlcMultiMouseHunterRoom:OnRoomLeaderTimeOut()
    if not XUiManager.CheckTopUi(CsXUiType.Normal, "UiDlcMultiPlayerRoomCute") then
        XLuaUiManager.Remove("UiDlcMultiPlayerRoomCute")
    end
end

function XDlcMultiMouseHunterRoom:OnKickOut(code)
    if code == XCode.DlcMultiplayerClose then
        XLuaUiManager.RunMain(true)
    else
        XLuaUiManager.SafeClose("UiSkip")
        XLuaUiManager.SafeClose("UiTip")
        XLuaUiManager.SafeClose("UiDialog")
        XLuaUiManager.SafeClose("UiReport")
        XLuaUiManager.SafeClose("UiPlayerInfo")
        XLuaUiManager.SafeClose("UiChatServeMain")
        XLuaUiManager.SafeClose("UiDlcMultiPlayerExchange")
        XLuaUiManager.SafeClose("UiDlcMultiPlayerShop")
        XLuaUiManager.SafeClose("UiDlcMultiPlayerTitle")
        XLuaUiManager.SafeClose("UiDlcMultiPlayerInvite")
        XLuaUiManager.SafeClose("UiDlcMultiPlayerCompetition")
        XLuaUiManager.SafeClose("UiDlcMultiPlayerGift")
        XLuaUiManager.SafeClose("UiDlcMultiPlayerSkill")
        XLuaUiManager.SafeClose("UiDlcMultiPlayerRoomCute")
        XLuaUiManager.SafeClose("UiDlcMultiPlayerSettlementBeach")
        XLuaUiManager.SafeClose("UiDlcMultiPlayerSettlementDorm")
        XLuaUiManager.SafeClose("UiDlcMultiPlayerSettlementMarket")
    end
end

function XDlcMultiMouseHunterRoom:OnCreateRoom()
    XLuaUiManager.SafeClose("UiDialog")
end

function XDlcMultiMouseHunterRoom:OnEnterWorld()
    XLuaUiManager.SafeClose("UiSkip")
    XLuaUiManager.SafeClose("UiDlcMultiPlayerMatchingPopup")
    XLuaUiManager.SafeClose("UiDialog")
    XLuaUiManager.SafeClose("UiPlayerInfo")
    XLuaUiManager.SafeClose("UiSocial")
    XLuaUiManager.SafeClose("UiReport")
    XLuaUiManager.SafeClose("UiCollectionWallView")
    XLuaUiManager.SafeClose("UiChatServeMain")
    XLuaUiManager.SafeClose("UiGuildRankingList")
    XLuaUiManager.SafeClose("UiDlcMultiPlayerTitle")
    XLuaUiManager.SafeClose("UiDlcMultiPlayerInvite")
    XLuaUiManager.SafeClose("UiDlcMultiPlayerShop")
    XLuaUiManager.SafeClose("UiPanelCharPropertyOtherV2P7")
    XLuaUiManager.SafeClose("UiCharacterAttributeDetail")
    XLuaUiManager.SafeClose("UiDlcMultiPlayerExchange")
    XLuaUiManager.SafeClose("UiFashionDetail")
    XLuaUiManager.SafeClose("UiPurchase")
    XLuaUiManager.SafeClose("UiPurchaseBuyTips")
    XLuaUiManager.SafeClose("UiObtain")
    XLuaUiManager.SafeClose("UiAccumulateRecharge")
    XLuaUiManager.SafeClose("UiFubenDialog")
    XLuaUiManager.SafeClose("UiTip")
    XLuaUiManager.SafeClose("UiCollectionTip")
    XLuaUiManager.SafeClose("UiUsePackage")
    XLuaUiManager.SafeClose("UiBuyAsset")
    XLuaUiManager.SafeClose("UiUseCoinPackage")
    XLuaUiManager.SafeClose("UiDlcMultiPlayerCompetition")
    XLuaUiManager.SafeClose("UiDlcMultiPlayerGift")
    XLuaUiManager.SafeClose("UiDlcMultiPlayerSkill")
end

return XDlcMultiMouseHunterRoom