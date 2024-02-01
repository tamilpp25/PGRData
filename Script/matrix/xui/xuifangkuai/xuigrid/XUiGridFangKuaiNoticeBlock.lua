---@class XUiGridFangKuaiNoticeBlock : XUiNode
---@field Parent XUiFangKuaiFight
---@field _Control XFangKuaiControl
local XUiGridFangKuaiNoticeBlock = XClass(XUiNode, "XUiGridFangKuaiNoticeBlock")

function XUiGridFangKuaiNoticeBlock:OnStart()
    self._Bodys = {}
end

---@param blockData XFangKuaiBlock
function XUiGridFangKuaiNoticeBlock:Update(blockData)
    self.ImgOne.sizeDelta = CS.UnityEngine.Vector2(blockData:GetLen() * 100, 12)
    local posX, _ = self._Control:GetPosByBlock(blockData)
    self.GridHeraldFangKuai.localPosition = CS.UnityEngine.Vector3(posX, 0, 0)
end

return XUiGridFangKuaiNoticeBlock