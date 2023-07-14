---@class XUiReformListGridBuff
local XUiReformListGridBuff = XClass(nil, "XUiReformListGridBuff")

function XUiReformListGridBuff:Ctor(ui, viewModel)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self._Data = false
    XUiHelper.RegisterClickEvent(self, self.Transform:GetComponent("XUiButton"), self.OnClick)
end

---@param iconData XUiReformAffixIconData
function XUiReformListGridBuff:Update(iconData)
    self._Data = iconData
    if not iconData then
        self.GameObject:SetActiveEx(false)
        return
    end
    self.GameObject:SetActiveEx(true)

    local isEmpty = iconData.IsEmpty
    if isEmpty then
        self.RImgBuff.gameObject:SetActiveEx(false)
        self.TextNone.gameObject:SetActiveEx(true)
    else
        local icon = iconData.Icon
        self.RImgBuff.gameObject:SetActiveEx(true)
        self.RImgBuff:SetRawImage(icon)
        self.TextNone.gameObject:SetActiveEx(false)
    end
end

function XUiReformListGridBuff:OnClick()
    if self._Data then
        local data = self._Data
        if not data.IsEmpty then
            XLuaUiManager.Open("UiReformBuffDetail", {
                Name = data.Name,
                Icon = data.Icon,
                Description = data.DescDetail,
            })
        end
    end
end

return XUiReformListGridBuff
