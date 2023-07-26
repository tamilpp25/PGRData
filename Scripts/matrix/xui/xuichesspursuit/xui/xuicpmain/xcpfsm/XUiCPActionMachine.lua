local XUiCPActionMachine = XClass(nil, "XUiCPActionMachine")
local XUiCPActionMove = require("XUi/XUiChessPursuit/XUi/XUiCPMain/XCPFSM/XUiCPActionMove")
local XUiCPActionBeginBattle = require("XUi/XUiChessPursuit/XUi/XUiCPMain/XCPFSM/XUiCPActionBeginBattle")
local XUiCPActionEndBattle = require("XUi/XUiChessPursuit/XUi/XUiCPMain/XCPFSM/XUiCPActionEndBattle")
local XUiCPActionEndBattleHurt = require("XUi/XUiChessPursuit/XUi/XUiCPMain/XCPFSM/XUiCPActionEndBattleHurt")
local XUiCPActionCardEffect = require("XUi/XUiChessPursuit/XUi/XUiCPMain/XCPFSM/XUiCPActionCardEffect")
local XUiCPActionEndRound = require("XUi/XUiChessPursuit/XUi/XUiCPMain/XCPFSM/XUiCPActionEndRound")

function XUiCPActionMachine.Create(actionType, params)
    local ActionMachine = {
        [XDataCenter.ChessPursuitManager.ChessPursuitSyncActionType.Move] = XUiCPActionMove,
        [XDataCenter.ChessPursuitManager.ChessPursuitSyncActionType.BeginBattle] = XUiCPActionBeginBattle,
        [XDataCenter.ChessPursuitManager.ChessPursuitSyncActionType.EndBattle] = XUiCPActionEndBattle,
        [XDataCenter.ChessPursuitManager.ChessPursuitSyncActionType.EndBattleHurt] = XUiCPActionEndBattleHurt,
        [XDataCenter.ChessPursuitManager.ChessPursuitSyncActionType.CardEffect] = XUiCPActionCardEffect,
        [XDataCenter.ChessPursuitManager.ChessPursuitSyncActionType.EndRound] = XUiCPActionEndRound,
    }

    if ActionMachine[actionType] then
        return ActionMachine[actionType].New(actionType, params)
    end
end

return XUiCPActionMachine