---@class XUiTempleBattleSmallRound : XUiNode
---@field PanelOn UnityEngine.RectTransform
---@field PanelOff UnityEngine.RectTransform
---@field TxtRoundNameOn UnityEngine.UI.Text
---@field TxtRoundNameOff UnityEngine.UI.Text
local XUiTempleBattleSmallRound = XClass(XUiNode, "XUiTempleBattleSmallRound")

---@param data XTempleUiDataSmallRound
function XUiTempleBattleSmallRound:Update(data)
    if data.IsActive then
        self.ImgOn.gameObject:SetActiveEx(true)
        self.ImgOff.gameObject:SetActiveEx(false)
    else
        self.ImgOff.gameObject:SetActiveEx(true)
        self.ImgOn.gameObject:SetActiveEx(false)
    end
end

return XUiTempleBattleSmallRound
