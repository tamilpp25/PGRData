---@class XUiTempleBattleGridPreviewScore : XUiNode
local XUiTempleBattleGridPreviewScore = XClass(XUiNode, "XUiTempleBattleGridPreviewScore")

---@param data XTempleGameControlPreviewScore
function XUiTempleBattleGridPreviewScore:Update(data)
    self.TxtName.text = data.Name
    self.TxtNum.text = data.Score
end

return XUiTempleBattleGridPreviewScore
