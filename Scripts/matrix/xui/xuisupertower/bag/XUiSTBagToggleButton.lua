--=============
--单选框选项
--=============
local XUiSTBagToggleButton = XClass(nil, "XUiSTBagToggleButton")

function XUiSTBagToggleButton:Ctor(btn, panel, index)
    self.Btn = btn
    self.Panel = panel
    self.Index = index
    self.IsSelect = false
    self.Btn.CallBack = function() self:OnClick() end
end

function XUiSTBagToggleButton:Reset()
    self.IsSelect = false
    self.Btn:SetButtonState(CS.UiButtonState.Normal)
end

function XUiSTBagToggleButton:OnClick()
    self.IsSelect = not self.IsSelect
    self.Btn:SetButtonState(self.IsSelect and CS.UiButtonState.Disable or CS.UiButtonState.Normal)
    if self.IsSelect then
        self.Panel:OnTogSelect(self.Index)
    else
        self.Panel:OnTogUnSelect(self.Index)
    end
end

return XUiSTBagToggleButton