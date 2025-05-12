---@class XUiConnectingLineGameAvatar:XUiNode
local XUiConnectingLineGameAvatar = XClass(XUiNode, "XUiConnectingLineGameAvatar")

function XUiConnectingLineGameAvatar:Ctor()
    ---@type UnityEngine.RectTransform
    self._GridBoardHead = false
end

function XUiConnectingLineGameAvatar:OnStart()
    self.HeadShang.gameObject:SetActiveEx(false)
end

function XUiConnectingLineGameAvatar:Update(avatarIcon, headGridBg)
    self.HeadImg:SetRawImage(avatarIcon)
    --self.HeadShang:SetSprite(headGridBg)
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

function XUiConnectingLineGameAvatar:SetConnected(value)
    --self.HeadShang.gameObject:SetActiveEx(value)
    self.ImageBg.gameObject:SetActiveEx(not value)
end

return XUiConnectingLineGameAvatar
