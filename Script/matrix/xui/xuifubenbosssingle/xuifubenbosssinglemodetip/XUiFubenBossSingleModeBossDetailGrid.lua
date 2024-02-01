---@class XUiFubenBossSingleModeBossDetailGrid : XUiNode
---@field RImgBossIcon UnityEngine.UI.RawImage
---@field TxtBoosName UnityEngine.UI.Text
---@field PanelBossLeftTime UnityEngine.RectTransform
---@field TxtBossLeftTime UnityEngine.UI.Text
---@field _Control XFubenBossSingleControl
local XUiFubenBossSingleModeBossDetailGrid = XClass(XUiNode, "XUiFubenBossSingleModeBossDetailGrid")

function XUiFubenBossSingleModeBossDetailGrid:OnStart(bossId)
    self.RImgBossIcon:SetRawImage(self._Control:GetBossIcon(bossId))
    self.TxtBoosName.text = self._Control:GetBossName(bossId)
end

return XUiFubenBossSingleModeBossDetailGrid
