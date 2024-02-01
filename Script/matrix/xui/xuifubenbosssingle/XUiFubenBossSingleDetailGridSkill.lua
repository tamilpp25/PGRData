---@class XUiFubenBossSingleDetailGridSkill : XUiNode
---@field TxtTitle UnityEngine.UI.Text
---@field TxtDesc UnityEngine.UI.Text
---@field ImgBg UnityEngine.UI.Image
---@field ImgBgHb UnityEngine.UI.Image
local XUiFubenBossSingleDetailGridSkill = XClass(XUiNode, "XUiFubenBossSingleDetailGridSkill")

function XUiFubenBossSingleDetailGridSkill:Refresh(title, desc, isHideBoss)
    self.TxtTitle.text = title
    self.TxtDesc.text = desc
    self.ImgBg.gameObject:SetActiveEx(not isHideBoss)
    self.ImgBgHb.gameObject:SetActiveEx(isHideBoss)
end

return XUiFubenBossSingleDetailGridSkill
