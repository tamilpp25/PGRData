---@class XUiTempleBattleRoundWithScore : XUiNode
---@field PanelOn UnityEngine.RectTransform
---@field PanelOff UnityEngine.RectTransform
---@field TxtRoundOn UnityEngine.UI.Text
---@field TxtRoundOff UnityEngine.UI.Text
---@field TxtNumOn UnityEngine.UI.Text
---@field TxtNumOff UnityEngine.UI.Text
local XUiTempleBattleRoundWithScore = XClass(XUiNode, "XUiTempleBattleRoundWithScore")

---@param data XTempleUiDataTimeWithScore
function XUiTempleBattleRoundWithScore:Update(data)
    self.Transform.name = data.UiName
    if data.IsActive then
        self.TxtNumOn.text = data.Score
        self.TxtRoundOn.text = data.Name
        self.PanelOn.gameObject:SetActiveEx(true)
        self.PanelOff.gameObject:SetActiveEx(false)
    else
        self.TxtNumOff.text = data.Score
        self.TxtRoundOff.text = data.Name
        self.PanelOff.gameObject:SetActiveEx(true)
        self.PanelOn.gameObject:SetActiveEx(false)
    end
end

return XUiTempleBattleRoundWithScore
