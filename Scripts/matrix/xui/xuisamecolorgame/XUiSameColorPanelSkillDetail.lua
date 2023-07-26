local XUiSameColorPanelSkillDetail = XClass(nil, "XUiSameColorPanelSkillDetail")

function XUiSameColorPanelSkillDetail:Ctor(ui)
    XUiHelper.InitUiClass(self, ui)
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnOn, self.OnBtnSwitchClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnOff, self.OnBtnSwitchClicked)
    -- XSCRoleSkill
    self.Skill = nil
end

-- skill : XSCRoleSkill
function XUiSameColorPanelSkillDetail:SetData(skill, isTimeType)
    self.Skill = skill
    self.IsTimeType = isTimeType
    self:RefreshSkillInfo()
end

function XUiSameColorPanelSkillDetail:RefreshSkillInfo()
    local skill = self.Skill
    self.RImgIcon:SetRawImage(skill:GetIcon())
    self.TxtName.text = skill:GetName()
    self.TxtSkillDesOff.text = skill:GetDesc(self.IsTimeType)
    self.TxtSkillDesOn.text = skill:GetDesc(self.IsTimeType)
    -- CD
    self.TxtCD.text = XUiHelper.GetText("SameColorGameRoleTip2", self.Skill:GetCD())
    -- 播放动画
    if self.AnimSwitch then -- 防打包
        self.AnimSwitch:Play()
    end
    -- local hasOn = self.Skill:GetIsHasOnSkill()
    -- if not hasOn then -- 如果没有on技能，直接显示off描述，隐藏切换按钮
    -- v1.31 3期不需要切换技能描述
    if true then
        self.TxtSkillDesOn.gameObject:SetActiveEx(false)
        self.TxtSkillDesOff.gameObject:SetActiveEx(true)
        self.BtnOn.gameObject:SetActiveEx(false)
        self.BtnOff.gameObject:SetActiveEx(false)
        self.TxtPower.gameObject:SetActiveEx(false)
        return 
    end
    -- 有on技能的处理
    local isOn = self.Skill:GetIsOn()
    -- 能量
    self.TxtPower.gameObject:SetActiveEx(isOn)
    if isOn then
        self.TxtPower.text = XUiHelper.GetText("SameColorGameRoleTip3", self.Skill:GetEnergyCost())
    end
    -- 切换按钮控制
    self.BtnOn.gameObject:SetActiveEx(not isOn)
    self.BtnOff.gameObject:SetActiveEx(isOn)
    self.TxtSkillDesOn.gameObject:SetActiveEx(isOn)
    self.TxtSkillDesOff.gameObject:SetActiveEx(not isOn)
end

function XUiSameColorPanelSkillDetail:Open()
    self.GameObject:SetActiveEx(true)
    XDataCenter.UiPcManager.OnUiEnable(self)
end

function XUiSameColorPanelSkillDetail:Close()
    self.GameObject:SetActiveEx(false)
    XDataCenter.UiPcManager.OnUiDisableAbandoned(true, self)
end

function XUiSameColorPanelSkillDetail:OnBtnSwitchClicked()
    self.Skill:ChangeSwitch()
    self:RefreshSkillInfo()
end

return XUiSameColorPanelSkillDetail