local XUiGridStage = require("XUi/XUiGuildWar/Map/XUiGridStage/XUiGridStage")

--四期封锁点
---@class XUiGridStageBlock:XUiGridStage
local XUiGridStageBlock = XClass(XUiGridStage, "XUiGridStageBlock")

function XUiGridStageBlock:Ctor()
    self._EffectLine1 = XUiHelper.TryGetComponent(self.Transform.parent, "EffectBlock1", "RectTransform")
    self._EffectLine2 = XUiHelper.TryGetComponent(self.Transform.parent, "EffectBlock2", "RectTransform")
    self._EffectLine3 = XUiHelper.TryGetComponent(self.Transform.parent, "EffectBlock3", "RectTransform")
end

---@param nodeEntity XGWNode
---@param panelStage XUiGuildWarPanelStage
function XUiGridStageBlock:UpdateGrid(nodeEntity, IsPathEdit, IsActionPlaying, isPathEditOver, panelStage)
    self.Super.UpdateGrid(self, nodeEntity, IsPathEdit, IsActionPlaying, isPathEditOver, panelStage)

    local node = self.StageNode
    if node:GetIsDead() then
        self:SetEffectBlockActive(false)
        if self._EffectLine1 then
            self._EffectLine1.gameObject:SetActiveEx(false)
            self._EffectLine2.gameObject:SetActiveEx(false)
            self._EffectLine3.gameObject:SetActiveEx(false)
        end
    else
        self:SetEffectBlockActive(true)
        if self._EffectLine1 then
            self._EffectLine1.gameObject:SetActiveEx(panelStage.StageGroupLine1.gameObject.activeSelf)
            self._EffectLine2.gameObject:SetActiveEx(panelStage.StageGroupLine2.gameObject.activeSelf)
            self._EffectLine3.gameObject:SetActiveEx(panelStage.StageGroupLine3.gameObject.activeSelf)
        end
    end
end

function XUiGridStageBlock:SetEffectBlockActive(value)
    local effect = XUiHelper.TryGetComponent(self.Transform.parent, "EffectBlock", "RectTransform")
    if effect then
        effect.gameObject:SetActiveEx(value)
    end
end

return XUiGridStageBlock