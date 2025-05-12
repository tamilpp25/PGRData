---@class XUiTempleBattleRound : XUiNode
---@field PanelOn UnityEngine.RectTransform
---@field PanelOff UnityEngine.RectTransform
---@field TxtRoundNameOn UnityEngine.UI.Text
---@field TxtRoundNameOff UnityEngine.UI.Text
local XUiTempleBattleRound = XClass(XUiNode, "XUiTempleBattleRound")

function XUiTempleBattleRound:OnStart()
    self.Text = XUiHelper.TryGetComponent(self.Transform, "Text", "Text")
end

---@param data XTempleUiDataTime
function XUiTempleBattleRound:Update(data)
    if data.IsActive then
        if self.TxtRoundNameOn then
            self.TxtRoundNameOn.text = data.Text
        elseif self.Text then
            self.Text.text = data.Text
        end
        self.PanelOn.gameObject:SetActiveEx(true)
        self.PanelOff.gameObject:SetActiveEx(false)
    else
        if self.TxtRoundNameOff then
            self.TxtRoundNameOff.text = data.Text
        elseif self.Text then
            self.Text.text = data.Text
        end
        self.PanelOff.gameObject:SetActiveEx(true)
        self.PanelOn.gameObject:SetActiveEx(false)
    end
end

return XUiTempleBattleRound
