---@class XUiDlcCasualGamesExchangeGrid : XUiNode
---@field RImgHeadIcon UnityEngine.UI.RawImage
---@field PanelSelected UnityEngine.RectTransform
---@field TxtRobotName UnityEngine.UI.Text
---@field TxtRobotTradeName UnityEngine.UI.Text
---@field ImgNow UnityEngine.UI.Image
---@field _Control XDlcCasualControl
local XUiDlcCasualGamesExchangeGrid = XClass(XUiNode, "XUiDlcCasualGamesExchangeGrid")

---@param character XDlcCasualCuteCharacter
function XUiDlcCasualGamesExchangeGrid:Refresh(character)
    self.RImgHeadIcon:SetRawImage(character:GetRoundHeadImage())
    self.TxtRobotName.text = character:GetName()
    self.TxtRobotTradeName.text = character:GetTradeName()
end

function XUiDlcCasualGamesExchangeGrid:SetSelect(isSelect)
    self.PanelSelected.gameObject:SetActiveEx(isSelect)
end

function XUiDlcCasualGamesExchangeGrid:SetCurrentSign(isCurrent)
    self.ImgNow.gameObject:SetActiveEx(isCurrent)
end

return XUiDlcCasualGamesExchangeGrid