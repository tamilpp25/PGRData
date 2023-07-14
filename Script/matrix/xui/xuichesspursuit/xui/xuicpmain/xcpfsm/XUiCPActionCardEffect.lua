local XUiCPActionBase = require("XUi/XUiChessPursuit/XUi/XUiCPMain/XCPFSM/XUiCPActionBase")
local XUiCPActionCardEffect = XClass(XUiCPActionBase, "XUiCPActionCardEffect")

function XUiCPActionCardEffect:OnEnter()
    self:SetIsFinish(false)
    
    --CardEffectId对应STEP表的ID
    if self.Params.ChessPursuitSyncAction:GetCardEffectId() then
        local stepId = self.Params.ChessPursuitSyncAction:GetCardEffectId()
        self.Params.UiRoot:RefreshBloodAndCount()
        if XChessPursuitConfig.CheckIsHaveStepCfgByCardEffectId(stepId) then
            local cfg = XChessPursuitConfig.GetChessPursuitStepTemplate(stepId)
            if cfg then
                self.Params.UiRoot:PlayStep(cfg.Id, function()
                    self:OnExit()
                end)
            end
        else
            local chessPursuitMapDb = XDataCenter.ChessPursuitManager.GetChessPursuitMapDb(self.Params.MapId)
            if chessPursuitMapDb:IsClear() then
                self.Params.UiRoot:PlayBossKillerAnimation(function ()
                    self:OnExit()
                end)
            else
                self:OnExit()
            end
        end
    else
        self:OnExit()
    end
end

function XUiCPActionCardEffect:OnStay()
    
end

function XUiCPActionCardEffect:OnExit()
    self:SetIsFinish(true)
end

return XUiCPActionCardEffect