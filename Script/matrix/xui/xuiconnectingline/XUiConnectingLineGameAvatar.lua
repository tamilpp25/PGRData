---@class XUiConnectingLineGameAvatar:XUiNode
local XUiConnectingLineGameAvatar = XClass(XUiNode, "XUiConnectingLineGameAvatar")

function XUiConnectingLineGameAvatar:Ctor()
    ---@type UnityEngine.RectTransform
    self._GridBoardHead = false
end

function XUiConnectingLineGameAvatar:Update(avatarIcon)
    self.HeadImg:SetRawImage(avatarIcon)
end

---@param gridBoardHead UnityEngine.RectTransform
function XUiConnectingLineGameAvatar:SetUiGridBoardHead(gridBoardHead)
    self._GridBoardHead = gridBoardHead
end

function XUiConnectingLineGameAvatar:SetPosition(x, y)
    local position = CS.UnityEngine.Vector2(x, y)

    ---@type UnityEngine.RectTransform
    local rectTransform = self.Transform:GetComponent("RectTransform")
    rectTransform.anchoredPosition = position

    ---@type UnityEngine.RectTransform
    local rectTransformBoard = self._GridBoardHead:GetComponent("RectTransform")
    rectTransformBoard.anchoredPosition = position
end

function XUiConnectingLineGameAvatar:Hide()
    self._GridBoardHead.gameObject:SetActiveEx(false)
    self:Close()
end

function XUiConnectingLineGameAvatar:Show()
    self._GridBoardHead.gameObject:SetActiveEx(true)
    self:Open()
end

return XUiConnectingLineGameAvatar
