local XUiGridSwitchSkill = XClass(nil, "XUiGridSwitchSkill")
local DescribeType = {
    Title = 1,
    Specific = 2,
}

function XUiGridSwitchSkill:Ctor(ui, switchCb)
    ---@type XCharacterAgency
    local ag = XMVCA:GetAgency(ModuleId.XCharacter)
    self.CharacterAgency = ag

    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.SwitchCb = switchCb
    XTool.InitUiObject(self)
    self.BtnSelect.CallBack = function()
        self:OnClickBtnSelect()
    end
    self.TxtSkillTitleGo = {}
    self.TxtSkillSpecificGo = {}
    self.TxtSkillName.gameObject:SetActiveEx(false)
    self.TxtSkillbrief.gameObject:SetActiveEx(false)
end

function XUiGridSwitchSkill:Refresh(skillId, skillLevel, isCurrent)
    self.SkillId = skillId

    self.SelectIcon.gameObject:SetActiveEx(isCurrent)
    self.BtnSelect.gameObject:SetActiveEx(not isCurrent)

    local gradeConfig = self.CharacterAgency:GetCharacterSkillExchangeDesBySkillIdAndLevel(skillId, skillLevel)
    if XTool.IsTableEmpty(gradeConfig) then
        gradeConfig = XCharacterConfigs.GetSkillGradeDesConfig(skillId, skillLevel)
    end
   
    -- 技能名
    self.TxtSkillBT.text = gradeConfig.Name
    -- 技能描述
    for _, go in pairs(self.TxtSkillTitleGo) do
        go:SetActiveEx(false)
    end
    for _, go in pairs(self.TxtSkillSpecificGo) do
        go:SetActiveEx(false)
    end
    for index, message in pairs(gradeConfig.SpecificDes or {}) do
        local title = gradeConfig.Title[index]
        if title then
            self:SetTextInfo(DescribeType.Title, index, title)
        end
        self:SetTextInfo(DescribeType.Specific, index, message)
    end
end

function XUiGridSwitchSkill:SetTextInfo(txtType, index, info)
    local txtSkillGo = {}
    local target
    if txtType == DescribeType.Title then
        txtSkillGo = self.TxtSkillTitleGo
        target = self.TxtSkillName.gameObject
    else
        txtSkillGo = self.TxtSkillSpecificGo
        target = self.TxtSkillbrief.gameObject
    end
    local txtGo = txtSkillGo[index]
    if not txtGo then
        txtGo = XUiHelper.Instantiate(target, self.PanelReward)
        txtSkillGo[index] = txtGo
    end
    txtGo:SetActiveEx(true)
    local goTxt = txtGo:GetComponent("Text")
    goTxt.text = XUiHelper.ConvertLineBreakSymbol(info)
    txtGo.transform:SetAsLastSibling()
end

function XUiGridSwitchSkill:OnClickBtnSelect()
    XDataCenter.CharacterManager.ReqSwitchSkill(self.SkillId, self.SwitchCb)
end

return XUiGridSwitchSkill