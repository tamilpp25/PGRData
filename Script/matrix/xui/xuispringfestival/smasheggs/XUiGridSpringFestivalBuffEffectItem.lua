local XUiGridSpringFestivalBuffEffectItem = XClass(nil, "XUiGridSpringFestivalBuffEffectItem")

function XUiGridSpringFestivalBuffEffectItem:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui
    XTool.InitUiObject(self)
end

function XUiGridSpringFestivalBuffEffectItem:Refresh(itemId)
    self.GameObject:SetActiveEx(itemId > 0)
    if itemId == 0 then return end
    local desc = XSpringFestivalActivityConfigs.GetBuffItemDesc(itemId)
    if self.TxtDescribe then
        self.TxtDescribe.text = desc
    end
end

return XUiGridSpringFestivalBuffEffectItem