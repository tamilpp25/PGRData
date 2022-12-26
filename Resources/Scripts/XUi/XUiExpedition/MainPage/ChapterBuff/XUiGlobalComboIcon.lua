--虚像地平线全局增益图标控件
local XUiGlobalComboIcon = XClass(nil, "XUiGlobalComboIcon")

function XUiGlobalComboIcon:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.RawBuffIcon = self.Transform:Find("RawBuffIcon"):GetComponent("RawImage")
end

function XUiGlobalComboIcon:RefreshData(comboConfig)
    self.GlobalComboId = comboConfig.Id
    self.GlobalComboConfig = comboConfig
    self.RawBuffIcon:SetRawImage(comboConfig.IconPath)
end

return XUiGlobalComboIcon