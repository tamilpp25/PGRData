local XUiCPActionBase = require("XUi/XUiChessPursuit/XUi/XUiCPMain/XCPFSM/XUiCPActionBase")
local XUiCPActionEndBattle = XClass(XUiCPActionBase, "XUiCPActionEndBattle")
local CSXChessPursuitDirection = CS.XChessPursuitDirection

function XUiCPActionEndBattle:OnEnter()
    self:SetIsFinish(false)

    XEventManager.AddEventListener(XEventId.EVENT_CHESSPURSUIT_FIGHT_FINISH_WIN, self.FightFinishWin, self)
end

function XUiCPActionEndBattle:OnStay()
    
end

function XUiCPActionEndBattle:FightFinishWin()
    self:OnExit()
end

function XUiCPActionEndBattle:OnExit()
    XEventManager.RemoveEventListener(XEventId.EVENT_CHESSPURSUIT_FIGHT_FINISH_WIN, self.FightFinishWin, self)
    
    self:SetIsFinish(true)
end

return XUiCPActionEndBattle