local XUiBuffGrid = XClass(nil, "XUiBuffGrid")

--黄金矿工通用Buff格子
function XUiBuffGrid:Ctor(ui, rootUi, clickCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.ClickCallback = clickCb
    XTool.InitUiObject(self)

    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnBtnClick)

    if self.CountDownText then
        self.CountDownText.gameObject:SetActiveEx(false)
    end
    self.GameObject:SetActiveEx(true)
end

function XUiBuffGrid:Refresh(buffId)
    self.BuffId = buffId
    local icon = XGoldenMinerConfigs.GetBuffIcon(buffId)
    if self.RawBuffIcon then
        self.RawBuffIcon:SetRawImage(icon)
    end
end

function XUiBuffGrid:OnBtnClick()
    local buffId = self.BuffId
    if self.ClickCallback then
        self.ClickCallback(buffId)
    end
end

return XUiBuffGrid