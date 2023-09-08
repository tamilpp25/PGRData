local XUiGridRiftMonsterDetail = XClass(nil, "XUiGridRiftMonsterDetail")

function XUiGridRiftMonsterDetail:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnBtnBackClick)
end

function XUiGridRiftMonsterDetail:Refresh(xMonster, xStageGroup, isFinish)
    self.XMonster = xMonster
    self.XStageGroup = xStageGroup
    self.RImgIcon:SetRawImage(xMonster:GetMonsterHeadIcon())
    if self.PanelDefeat then
        self.PanelDefeat.gameObject:SetActiveEx(isFinish)
    end
end

function XUiGridRiftMonsterDetail:OnBtnBackClick()
    XLuaUiManager.Open("UiRiftAffix", self.XStageGroup, self.XMonster)
end

return XUiGridRiftMonsterDetail
