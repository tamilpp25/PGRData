local XUiCPActionBase = require("XUi/XUiChessPursuit/XUi/XUiCPMain/XCPFSM/XUiCPActionBase")
local XUiCPActionMove = XClass(XUiCPActionBase, "XUiCPActionMove")
local CSXChessPursuitState = CS.XChessPursuitState
local CSXChessPursuitDirection = CS.XChessPursuitDirection

function XUiCPActionMove:OnEnter()
    self:SetIsFinish(false)

    self.CSXChessPursuitBoss = self.Params.UiRoot.ChessPursuitBoss:GetCSXChessPursuitModel()
    local CSXChessPursuitCtrlCom = XChessPursuitCtrl.GetCSXChessPursuitCtrlCom()
    --要到达的位置
    local bossPos = self.Params.ChessPursuitSyncAction:GetBoosPos()
    --场景中BOSS的位置
    local currentPos = self.CSXChessPursuitBoss:GetCurrentIndex()
    local direction = XChessPursuitCtrl.GetMoveDirection(currentPos, bossPos)
    
    if currentPos == bossPos then
        local chessPursuitMapDb = XDataCenter.ChessPursuitManager.GetChessPursuitMapDb(self.Params.MapId)
        --服务器最新的方向
        local serverDir = chessPursuitMapDb:GetBossMoveDirection()
        --本地客户端的方向
        local localDir = CSXChessPursuitCtrlCom:GetChessPursuitDirection()
        if serverDir ~= localDir then
            self.CSXChessPursuitBoss:SwitchState(CSXChessPursuitState.TurnBack, function ()
                self:OnExit()
            end, serverDir)
        else
            self:OnExit()
        end
    elseif direction then
        self.CSXChessPursuitBoss:SwitchState(CSXChessPursuitState.TurnBack, function ()
            self:Move()
        end, direction)
    else
        self:Move()
    end
end

function XUiCPActionMove:Move()
    CS.XAudioManager.PlaySound(XSoundManager.UiBasicsMusic.ChessPursuit_BossJump)
    --一步一步走
    self.CSXChessPursuitBoss:SwitchState(CSXChessPursuitState.Move, function ()
        self:OnExit()
        self.Params.UiRoot:RefreshTeamActive()
    end, 1)
end

function XUiCPActionMove:OnStay()
    
end

function XUiCPActionMove:OnExit()
    self:SetIsFinish(true)
end

return XUiCPActionMove