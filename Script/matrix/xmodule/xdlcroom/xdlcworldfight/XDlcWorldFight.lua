---@class XDlcWorldFight
local XDlcWorldFight = XClass(nil, "XDlcWorldFight")

function XDlcWorldFight:OnFightFinishSettle(worldType, settleData, isWin)
    XLuaUiManager.Open("UiSettleLose")
end

function XDlcWorldFight:OnFightForceExit(worldType)
    XLuaUiManager.Open("UiSettleLose")
end

return XDlcWorldFight