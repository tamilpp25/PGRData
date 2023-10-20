local CSVector2 = CS.UnityEngine.Vector2
---@class XUiPanelRogueSimBaseBubble : XUiNode
---@field private _Control XRogueSimControl
local XUiPanelRogueSimBaseBubble = XClass(XUiNode, "XUiPanelRogueSimBaseBubble")

function XUiPanelRogueSimBaseBubble:OnStart()
    self.CurAlignment = 0
    self:SetAnchorAndPivot()
end

function XUiPanelRogueSimBaseBubble:GetAlignment()
    if self.CurAlignment == XEnumConst.RogueSim.Alignment.LT then
        return CSVector2(0, 1)
    elseif self.CurAlignment == XEnumConst.RogueSim.Alignment.RT then
        return CSVector2(1, 1)
    elseif self.CurAlignment == XEnumConst.RogueSim.Alignment.LB then
        return CSVector2(0, 0)
    elseif self.CurAlignment == XEnumConst.RogueSim.Alignment.RB then
        return CSVector2(1, 0)
    elseif self.CurAlignment == XEnumConst.RogueSim.Alignment.CT then
        return CSVector2(0.5, 1)
    elseif self.CurAlignment == XEnumConst.RogueSim.Alignment.CB then
        return CSVector2(0.5, 0)
    elseif self.CurAlignment == XEnumConst.RogueSim.Alignment.LC then
        return CSVector2(0, 0.5)
    elseif self.CurAlignment == XEnumConst.RogueSim.Alignment.RC then
        return CSVector2(1, 0.5)
    elseif self.CurAlignment == XEnumConst.RogueSim.Alignment.LTB then
        return CSVector2(0, 1)
    elseif self.CurAlignment == XEnumConst.RogueSim.Alignment.RTB then
        return CSVector2(1, 1)
    end
    return CSVector2(0.5, 0.5)
end

function XUiPanelRogueSimBaseBubble:SetAnchorAndPivot()
    self.Transform.anchorMin = CSVector2(0.5, 0.5)
    self.Transform.anchorMax = CSVector2(0.5, 0.5)
    self.Transform.pivot = self:GetAlignment()
end

---@param targetTransform UnityEngine.RectTransform
function XUiPanelRogueSimBaseBubble:SetTransform(targetTransform)
    -- 超框处理
    local centerW = self.Transform.parent.rect.width / 2
    local tipW = self.Transform.rect.width
    local minW = -centerW
    local maxW = centerW

    local pos = self.Transform.parent:InverseTransformPoint(targetTransform.position)
    local x = pos.x
    local y = pos.y
    if self.CurAlignment == XEnumConst.RogueSim.Alignment.LT then
        x = x + targetTransform.rect.width * targetTransform.localScale.x * (1 - targetTransform.pivot.x)
        y = y + targetTransform.rect.height * targetTransform.localScale.y * (1 - targetTransform.pivot.y)
        maxW = centerW - tipW
    elseif self.CurAlignment == XEnumConst.RogueSim.Alignment.RT then
        x = x - targetTransform.rect.width * targetTransform.localScale.x * targetTransform.pivot.x
        y = y + targetTransform.rect.height * targetTransform.localScale.y * (1 - targetTransform.pivot.y)
        minW = tipW - centerW
    elseif self.CurAlignment == XEnumConst.RogueSim.Alignment.LB then
        x = x + targetTransform.rect.width * targetTransform.localScale.x * (1 - targetTransform.pivot.x)
        y = y - targetTransform.rect.height * targetTransform.localScale.y * targetTransform.pivot.y
        maxW = centerW - tipW
    elseif self.CurAlignment == XEnumConst.RogueSim.Alignment.RB then
        x = x - targetTransform.rect.width * targetTransform.localScale.x * targetTransform.pivot.x
        y = y - targetTransform.rect.height * targetTransform.localScale.y * targetTransform.pivot.y
        minW = tipW - centerW
    elseif self.CurAlignment == XEnumConst.RogueSim.Alignment.CT then
        y = y - targetTransform.rect.height * targetTransform.localScale.y * targetTransform.pivot.y
        minW = tipW / 2 - centerW
        maxW = centerW - tipW / 2
    elseif self.CurAlignment == XEnumConst.RogueSim.Alignment.CB then
        y = y + targetTransform.rect.height * targetTransform.localScale.y * (1 - targetTransform.pivot.y)
        minW = tipW / 2 - centerW
        maxW = centerW - tipW / 2
    elseif self.CurAlignment == XEnumConst.RogueSim.Alignment.LC then
        x = x + targetTransform.rect.width * targetTransform.localScale.x * (1 - targetTransform.pivot.x)
        maxW = centerW - tipW
    elseif self.CurAlignment == XEnumConst.RogueSim.Alignment.RC then
        x = x - targetTransform.rect.width * targetTransform.localScale.x * targetTransform.pivot.x
        minW = tipW - centerW
    elseif self.CurAlignment == XEnumConst.RogueSim.Alignment.LTB then
        x = x - targetTransform.rect.width * targetTransform.localScale.x * targetTransform.pivot.x
        y = y - targetTransform.rect.height * targetTransform.localScale.y * targetTransform.pivot.y
        maxW = centerW - tipW
    elseif self.CurAlignment == XEnumConst.RogueSim.Alignment.RTB then
        x = x + targetTransform.rect.width * targetTransform.localScale.x * (1 - targetTransform.pivot.x)
        y = y - targetTransform.rect.height * targetTransform.localScale.y * targetTransform.pivot.y
        minW = tipW - centerW
    end
    x = math.min(math.max(x, minW), maxW)
    self.Transform.anchoredPosition = CSVector2(x, y)
end

return XUiPanelRogueSimBaseBubble
