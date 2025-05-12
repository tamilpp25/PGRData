local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")

-- 未继承XUiNode, 某些通用道具类，未继承XUiNode（XUiGridCommon）, 导致界面打开时，会有相关节点显隐报错
---@class XUiGridGoodsTag 道具标签
---@field Transform UnityEngine.RectTransform
local XUiGridGoodsTag = XClass(nil, "XUiGridGoodsTag")

local CsVec2Half = Vector2(0.5, 0.5)

function XUiGridGoodsTag:Ctor(ui, parent)
    XTool.InitUiObjectByUi(self, ui)
    self.Parent = parent
    self.Offset = Vector2.zero
end

function XUiGridGoodsTag:Refresh(templateId, isFixedPosition)
    local template = XUiConfigs.GetGoodsLabelTemplate(templateId)
    if not template then
        self:Close()
        return
    end
    if not isFixedPosition then
        self:RefreshLocation(template.Location)
        self.Offset.x = template.OffsetX
        self.Offset.y = template.OffsetY
        self.Transform.anchoredPosition = self.Offset
    end
    if not string.IsNilOrEmpty(template.Icon) then
        self.ImgIcon:SetRawImage(template.Icon)
    end
    
    self:Open()
end

function XUiGridGoodsTag:Open()
    self.GameObject:SetActiveEx(true)
end

function XUiGridGoodsTag:Close()
    self.GameObject:SetActiveEx(false)
end

function XUiGridGoodsTag:RefreshLocation(location)
    if location == XUiConfigs.LabelLocation.RT then
        self.Transform.anchorMin = Vector2.one
        self.Transform.anchorMax = Vector2.one
        self.Transform.pivot = Vector2.one
    elseif location == XUiConfigs.LabelLocation.RB then
        self.Transform.anchorMin = Vector2.right
        self.Transform.anchorMax = Vector2.right
        self.Transform.pivot = Vector2.right
    elseif location == XUiConfigs.LabelLocation.LB then
        self.Transform.anchorMin = Vector2.zero
        self.Transform.anchorMax = Vector2.zero
        self.Transform.pivot = Vector2.zero
    elseif location == XUiConfigs.LabelLocation.LT then
        self.Transform.anchorMin = Vector2.up
        self.Transform.anchorMax = Vector2.up
        self.Transform.pivot = Vector2.up
    elseif location == XUiConfigs.LabelLocation.MID then
        self.Transform.anchorMin = CsVec2Half
        self.Transform.anchorMax = CsVec2Half
        self.Transform.pivot = CsVec2Half
    end
end

return XUiGridGoodsTag