--######################## XUiPanelEliteMonster ########################
local XUiPanelEliteMonster = XClass(XSignalData, "XUiPanelEliteMonster")

function XUiPanelEliteMonster:Ctor(ui)
    XUiHelper.InitUiClass(self, ui)
    XUiHelper.RegisterClickEvent(self, self.BtnChange, self.OnBtnChangeClicked)
end

function XUiPanelEliteMonster:SetData(monster)
    if monster == nil then return end
    self.RImgIcon:SetRawImage(monster:GetIcon())
    self.TxtName.text = monster:GetName()
    self.TxtHP.text = monster:GetPercentageHP() .. "%"
    self.TxtMyDamage.text = XUiHelper.GetText("GuildWarMaxDamageTip"
        , getRoundingValue((monster:GetMaxDamage() / monster:GetMaxHP()) * 100, 2))
    self.PrograssHP.fillAmount = monster:GetHP() / monster:GetMaxHP()
    self.BtnChange.gameObject:SetActiveEx(true)
    -- 设置按钮名称
    self.BtnChange:SetNameByGroup(0, XUiHelper.GetText("GuildWarChangeNode"))
end

function XUiPanelEliteMonster:OnBtnChangeClicked()
    self:EmitSignal("ChangeTopDetailStatus", false)
end

return XUiPanelEliteMonster