local XUiGridStage = require("XUi/XUiGuildWar/Map/XUiGridStage/XUiGridStage")

--四期封锁点
---@class XUiGridStageBlock:XUiGridStage
local XUiGridStageBlock = XClass(XUiGridStage, "XUiGridStageBlock")

---@param nodeEntity XGWNode
function XUiGridStageBlock:UpdateGrid(...)
    self.Super.UpdateGrid(self, ...)
    
    local node = self.StageNode
    if node:GetIsDead() then
        self:SetEffectBlockActive(false)
    else
        self:SetEffectBlockActive(true)
    end
end

function XUiGridStageBlock:SetEffectBlockActive(value)
    local effect = XUiHelper.TryGetComponent(self.Transform.parent, "EffectBlock", "RectTransform")
    if effect then
        effect.gameObject:SetActiveEx(value)
    end
end

return XUiGridStageBlock