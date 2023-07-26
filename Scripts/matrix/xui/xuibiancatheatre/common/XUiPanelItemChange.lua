local XUiPanelItemChange = XClass(nil, "XUiPanelItemChange")

function XUiPanelItemChange:Ctor(ui, itemId)
    XUiHelper.InitUiClass(self, ui)
    self.ItemId = itemId
    self.ItemCount = XDataCenter.ItemManager.GetCount(self.ItemId)

    self.EffectZeng = XUiHelper.TryGetComponent(self.Transform, "PanelEffect/EffectEnergyZeng")
    self.EffectJian = XUiHelper.TryGetComponent(self.Transform, "PanelEffect/EffectEnergyJian")
    if not self.EffectZeng then
        self.EffectZeng = XUiHelper.TryGetComponent(self.Transform, "PanelEffect/EffectEnergyZeng2")
    end
    if not self.EffectJian then
        self.EffectJian = XUiHelper.TryGetComponent(self.Transform, "PanelEffect/EffectEnergyJian2")
    end

    self.GameObject:SetActiveEx(false)
    if self.EffectZeng then self.EffectZeng.gameObject:SetActiveEx(false) end
    if self.EffectJian then self.EffectJian.gameObject:SetActiveEx(false) end
    XDataCenter.ItemManager.AddCountUpdateListener(self.ItemId, handler(self, self.SetChange), self)
end

function XUiPanelItemChange:SetChange()
    if self.IsClose or XTool.UObjIsNil(self.Transform) then
        return
    end
    local value = XDataCenter.ItemManager.GetCount(self.ItemId) - self.ItemCount
    if value ~= 0 then
        local txt = value > 0 and "+"..value or value
        self.EnergyCountText:TextToSprite(txt, value > 0 and 0 or 1)
    end
    self.ItemCount = XDataCenter.ItemManager.GetCount(self.ItemId)
    if self.EffectZeng then
        self.EffectZeng.gameObject:SetActiveEx(value > 0)
    end
    if self.EffectJian then
        self.EffectJian.gameObject:SetActiveEx(value < 0)
    end
    self.GameObject:SetActiveEx(false)
    self.GameObject:SetActiveEx(true)
end

function XUiPanelItemChange:Refresh(isClose)
    if XTool.UObjIsNil(self.Transform) then
        return
    end
    self.GameObject:SetActiveEx(false)
    self.IsClose = isClose
end

return XUiPanelItemChange