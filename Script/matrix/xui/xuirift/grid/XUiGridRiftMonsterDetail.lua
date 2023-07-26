local XUiGridRiftMonsterDetail = XClass(nil, "XUiGridRiftMonsterDetail")

function XUiGridRiftMonsterDetail:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnBtnBackClick)
end

function XUiGridRiftMonsterDetail:Refresh(xMonster, xStageGroup)
    self.XMonster = xMonster
    self.XStageGroup = xStageGroup
    self.RImgIcon:SetRawImage(xMonster:GetMonsterHeadIcon())
end

function XUiGridRiftMonsterDetail:OnBtnBackClick()
    XLuaUiManager.Open("UiRiftAffix", self.XStageGroup, self.XMonster)
end

return XUiGridRiftMonsterDetail
