local XDlcWorldFight = require("XModule/XDlcRoom/XDlcWorldFight/XDlcWorldFight")
local XDlcCasualResult = require("XModule/XDlcCasual/XEntity/XDlcCasualResult")

---@class XDlcCasualWorldFight : XDlcWorldFight
local XDlcCasualWorldFight = XClass(XDlcWorldFight, "XDlcCasualWorldFight")

function XDlcCasualWorldFight:OnFightFinishSettle(worldType, settleData, isWin)
    if isWin then
        local resultData = settleData.CasualCubeResultData
        local playerResultData = settleData.ResultData.ReJoinWorldExpireTime
        ---@type XDlcCasualResult
        local result = XDlcCasualResult.New(resultData, playerResultData)

        XLuaUiManager.Open("UiDlcCasualplayerSettlement", result)
    else
        XLuaUiManager.Open("UiDlcSettleLose")
    end
end

function XDlcCasualWorldFight:OnFightForceExit(worldType)
    XLuaUiManager.Open("UiDlcSettleLose")
    XLuaUiManager.SafeClose("UiDlcCasualplayerRoomCute")
end

return XDlcCasualWorldFight
