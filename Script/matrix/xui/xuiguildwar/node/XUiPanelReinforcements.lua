--######################## XUiPanelReinforcements ########################
-- 显示标题：名称、血量、图标等
local XUiPanelReinforcements = XClass(XSignalData, "XUiPanelReinforcements")

function XUiPanelReinforcements:Ctor(ui)
    XUiHelper.InitUiClass(self, ui)
    XUiHelper.RegisterClickEvent(self, self.BtnChange, self.OnBtnChangeClicked)
end

function XUiPanelReinforcements:SetData(reinforcements)
    if reinforcements == nil or
            not XDataCenter.GuildWarManager.CheckRoundIsInTime()
    then
        self.GameObject:SetActiveEx(false)
        return
    end
    self.GameObject:SetActiveEx(true)
    self.RImgIcon:SetRawImage(reinforcements:GetIcon())
    self.TxtName.text = reinforcements:GetReinforcementName()
    self.TxtHP.text = reinforcements:GetPercentageHP() .. "%"
    self.TxtMyDamage.text = ''
    self.PrograssHP.fillAmount = reinforcements:GetHP() / reinforcements:GetMaxHP()
    -- 设置按钮名称
    self.BtnChange:SetNameByGroup(0, XUiHelper.GetText("GuildWarChangeNode"))
end

function XUiPanelReinforcements:OnBtnChangeClicked()
    self:EmitSignal("ChangeTopDetailStatus", false)
end

return XUiPanelReinforcements