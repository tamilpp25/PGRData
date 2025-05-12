local XChessPursuitCtrl = require("XUi/XUiChessPursuit/XChessPursuitCtrl")
local XUiCPActionBase = require("XUi/XUiChessPursuit/XUi/XUiCPMain/XCPFSM/XUiCPActionBase")
local XUiCPActionBeginBattle = XClass(XUiCPActionBase, "XUiCPActionBeginBattle")
local CSXChessPursuitDirection = CS.XChessPursuitDirection

function XUiCPActionBeginBattle:OnEnter()
    self:SetIsFinish(false)
    local CSXChessPursuitBoss = self.Params.UiRoot.ChessPursuitBoss:GetCSXChessPursuitModel()

    local chessPursuitMapDb = XDataCenter.ChessPursuitManager.GetChessPursuitMapDb(self.Params.MapId)
    local bossPos = chessPursuitMapDb:GetBossPos()
    local teamGridIndex = XChessPursuitConfig.GetTeamGridIndexByPos(self.Params.MapId, bossPos)

    if not teamGridIndex then
        XLog.Error(string.format("触发战斗失败，MapId:%s  ChessPursuitMap.tab的TeamGrid没有找到位置：%s", self.Params.MapId, bossPos))
        self:OnExit()
        return
    end

    self.Params.UiRoot.PanelTipsfighting.gameObject:SetActiveEx(true)

    self.Params.ParentUiRoot:PlayAnimationWithMask("PanelTipsfightingEnable", function()
        self.Params.UiRoot.PanelTipsfighting.gameObject:SetActiveEx(false)

        local csXChessPursuitCtrlCom = XChessPursuitCtrl.GetCSXChessPursuitCtrlCom()
        local chessPursuitDrawCamera = csXChessPursuitCtrlCom and csXChessPursuitCtrlCom:GetChessPursuitDrawCamera()
        XLuaUiManager.Open("UiChessPursuitFightTips", self.Params.MapId, teamGridIndex, function ()
            XChessPursuitCtrl.SetSceneActive(false)
            self:OnExit()
        end, self.Params.ParentUiRoot, chessPursuitDrawCamera)
    end)

    XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.ChessPursuit_FightWarning)
end

function XUiCPActionBeginBattle:OnStay()
    
end

function XUiCPActionBeginBattle:OnExit()
    self:SetIsFinish(true)
end

return XUiCPActionBeginBattle