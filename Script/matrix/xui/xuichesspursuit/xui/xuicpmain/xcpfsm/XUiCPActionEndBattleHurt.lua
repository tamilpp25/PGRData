local XChessPursuitCtrl = require("XUi/XUiChessPursuit/XChessPursuitCtrl")
local XUiCPActionBase = require("XUi/XUiChessPursuit/XUi/XUiCPMain/XCPFSM/XUiCPActionBase")
local XUiCPActionEndBattleHurt = XClass(XUiCPActionBase, "XUiCPActionEndBattleHurt")

function XUiCPActionEndBattleHurt:OnEnter()
    self:SetIsFinish(false)

    XChessPursuitCtrl.SetSceneActive(true)
    
    local chessPursuitMapDb = XDataCenter.ChessPursuitManager.GetChessPursuitMapDb(self.Params.MapId)
    if chessPursuitMapDb:IsClear() then
        self.Params.UiRoot:PlayBossKillerAnimation(function ()
            self:OnExit()
        end)
    else
        self:OnExit()
    end
end

function XUiCPActionEndBattleHurt:OnStay()
    
end

function XUiCPActionEndBattleHurt:OnExit()
    self:SetIsFinish(true)
end

return XUiCPActionEndBattleHurt