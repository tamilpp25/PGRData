local XChessPursuitCtrl = require("XUi/XUiChessPursuit/XChessPursuitCtrl")
local XUiCPActionBase = require("XUi/XUiChessPursuit/XUi/XUiCPMain/XCPFSM/XUiCPActionBase")
local XUiCPActionEndRound = XClass(XUiCPActionBase, "XUiCPActionEndRound")
local CSXChessPursuitState = CS.XChessPursuitState

function XUiCPActionEndRound:OnEnter()
    self:SetIsFinish(false)
    
    local CSXChessPursuitCtrlCom = XChessPursuitCtrl.GetCSXChessPursuitCtrlCom()
    local chessPursuitMapDb = XDataCenter.ChessPursuitManager.GetChessPursuitMapDb(self.Params.MapId)
    self.CSXChessPursuitBoss = self.Params.UiRoot.ChessPursuitBoss:GetCSXChessPursuitModel()

    --回合结束前检测朝向是否与服务端的一致
    if CSXChessPursuitCtrlCom:GetChessPursuitDirection() ~= chessPursuitMapDb:GetBossMoveDirection() then
        self.CSXChessPursuitBoss:SwitchState(CSXChessPursuitState.TurnBack, function ()
            self:OnExit()
        end, chessPursuitMapDb:GetBossMoveDirection())
    else
        self:OnExit()
    end
end

function XUiCPActionEndRound:OnStay()
    
end

function XUiCPActionEndRound:OnExit()
    --EndRound必定到自己的回合
    self.Params.UiRoot:SetEndRound(true)
    self:SetIsFinish(true)
end

return XUiCPActionEndRound