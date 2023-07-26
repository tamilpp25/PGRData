--分光双星全局增益图标控件
local XUiGlobalComboIcon = XClass(nil, "XUiGlobalComboIcon")

function XUiGlobalComboIcon:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.RawBuffIcon = XUiHelper.TryGetComponent(self.Transform, "RawBuffIcon", "RawImage")
end

function XUiGlobalComboIcon:RefreshData(showFightEventId)
    local config = XFubenConfigs.GetStageFightEventDetailsByStageFightEventId(showFightEventId)
    self.RawBuffIcon:SetRawImage(config.Icon)
end

return XUiGlobalComboIcon