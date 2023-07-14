local XUiGridRiftAffixMonster = XClass(nil, "XUiGridRiftAffixMonster")

function XUiGridRiftAffixMonster:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self.Btn.CallBack = function () self:OnBtnClick() end 
end

function XUiGridRiftAffixMonster:Refresh(xMonster, index)
    self.XMonster = xMonster
    self.Index = index
    self.Btn:SetRawImage(xMonster:GetConfig().HeadIcon)
end

function XUiGridRiftAffixMonster:SetSelect(value)
    if value then
        self.Btn:SetButtonState(CS.UiButtonState.Select)
    else
        self.Btn:SetButtonState(CS.UiButtonState.Normal)
    end
end

function XUiGridRiftAffixMonster:OnBtnClick()
    self.RootUi:OnGridMonsterClick(self)
end

return XUiGridRiftAffixMonster