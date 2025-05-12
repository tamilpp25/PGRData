---@class XUiGridStrongholdAnimation : XUiNode
---@field Parent XUiStrongholdAnimation
local XUiGridStrongholdAnimation = XClass(XUiNode, "XUiGridStrongholdAnimation")

function XUiGridStrongholdAnimation:OnStart()

end

function XUiGridStrongholdAnimation:Refresh(buffId, isBossBuff)
    local isBuffActive = XDataCenter.StrongholdManager.CheckBuffActive(buffId, isBossBuff)
    if not self._Buff then
        ---@type XUiGridStrongholdBuff
        self._Buff = require("XUi/XUiStronghold/XUiGridStrongholdBuff").New(self.GridBuffBoss, true)
    end
    self._Buff:Refresh(buffId, isBossBuff)
    self._Buff:SetDisable(false)
    self.TxtName.text = XStrongholdConfigs.GetBuffName(buffId)
    self.TxtDetail.text = XStrongholdConfigs.GetBuffDesc(buffId)
    self.PanelLock.gameObject:SetActiveEx(not isBuffActive)
end

return XUiGridStrongholdAnimation