--=============
--筛选框选项
--=============
local XUiSTBagIllusFilterButton = XClass(nil, "XUiSTBagIllusFilterButton")

function XUiSTBagIllusFilterButton:Ctor(btn, panel, index)
    self.Btn = btn
    self.Panel = panel
    self.Index = index
    self.IsSelect = false
    self.Btn.CallBack = function() self:OnClick() end
end

function XUiSTBagIllusFilterButton:Reset()
    self.IsSelect = false
    self.Btn:SetButtonState(CS.UiButtonState.Normal)
end

function XUiSTBagIllusFilterButton:OnClick()
    self.IsSelect = not self.IsSelect
    self.Btn:SetButtonState(self.IsSelect and CS.UiButtonState.Disable or CS.UiButtonState.Normal)
    if self.IsSelect then
        self.Panel:OnTogSelect(self.Index)
    else
        self.Panel:OnTogUnSelect(self.Index)
    end
end

return XUiSTBagIllusFilterButton