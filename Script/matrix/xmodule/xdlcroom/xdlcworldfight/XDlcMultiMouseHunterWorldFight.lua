local XDlcWorldFight = require("XModule/XDlcRoom/XDlcWorldFight/XDlcWorldFight")
local XDlcMultiMouseHunterResult = require("XModule/XDlcMultiMouseHunter/XEntity/XDlcMultiMouseHunterResult")

---@class XDlcMultiMouseHunterWorldFight : XDlcWorldFight
local XDlcMultiMouseHunterWorldFight = XClass(XDlcWorldFight, "XDlcMultiMouseHunterWorldFight")

function XDlcMultiMouseHunterWorldFight:OnFightFinishSettle(worldType, settleData, isWin, isCheat)
    local resultData = settleData.MultiplayerMouseHunterResultData
    local settleState = settleData.ResultData.SettleState
    local worldData = settleData.ResultData.WorldData
    local worldId = worldData and worldData.WorldId or 0
    local levelId = worldData and worldData.LevelId or 0
    
    if resultData then
        ---@type XDlcMultiMouseHunterResult
        local result = XDlcMultiMouseHunterResult.New(resultData, settleState == XEnumConst.DlcWorld.SettleState.AdvanceExit, worldId, levelId)

        -- XLuaUiManager.Open("UiDlcMultiPlayerSettlement", result, isCheat)
        XMVCA.XDlcMultiMouseHunter:OpenSettmentUi(result)
    else
        XLuaUiManager.Open("UiDlcSettleLose")
    end
end

function XDlcMultiMouseHunterWorldFight:OnFightForceExit(worldType)
    XLuaUiManager.Open("UiDlcSettleLose")
    XLuaUiManager.SafeClose("UiDlcMultiPlayerRoomCute")
end

return XDlcMultiMouseHunterWorldFight
