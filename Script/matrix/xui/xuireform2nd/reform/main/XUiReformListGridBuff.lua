---@class XUiReformListGridBuff
local XUiReformListGridBuff = XClass(nil, "XUiReformListGridBuff")

function XUiReformListGridBuff:Ctor(ui, viewModel)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self._Data = false
    local button = self.Transform:GetComponent("XUiButton")
    XUiHelper.RegisterClickEvent(self, button, self.OnClick)
end

---@param iconData XReformAffixData
function XUiReformListGridBuff:Update(iconData)
    self._Data = iconData
    local icon = iconData.Icon
    self.RawImage.gameObject:SetActiveEx(true)
    self.RawImage:SetRawImage(icon)
    self.Text.text = iconData.Name
    self.Text2.text = iconData.Desc
    self.TxtRepulsion.text = iconData.Name
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
