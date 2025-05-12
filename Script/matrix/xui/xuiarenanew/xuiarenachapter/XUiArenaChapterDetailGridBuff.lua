---@class XUiArenaChapterDetailGridBuff : XUiNode
---@field ImgBuff UnityEngine.UI.Image
---@field TxtTitle UnityEngine.UI.Text
---@field TxtDetail UnityEngine.UI.Text
---@field _Control XArenaControl
local XUiArenaChapterDetailGridBuff = XClass(XUiNode, "XUiArenaChapterDetailGridBuff")

function XUiArenaChapterDetailGridBuff:Refresh(buffId)
    self.ImgBuff:SetSprite(self._Control:GetBuffDetailsIconById(buffId))
    self.TxtTitle.text = self._Control:GetBuffDetailsNameById(buffId)
    self.TxtDetail.text = self._Control:GetBuffDetailsDescById(buffId)
end

return XUiArenaChapterDetailGridBuff
