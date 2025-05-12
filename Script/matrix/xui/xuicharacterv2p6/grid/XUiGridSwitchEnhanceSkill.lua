---@class XUiGridSwitchEnhanceSkill XUiGridSwitchEnhanceSkill
---@field _Control XCharacterControl
local XUiGridSwitchEnhanceSkill = XClass(XUiNode, "XUiGridSwitchEnhanceSkill")
local DescribeType = {
    Title = 1,
    Specific = 2,
}

function XUiGridSwitchEnhanceSkill:Ctor(ui, parent, switchCb)
    self.SwitchCb = switchCb
    self.BtnSelect.CallBack = function()
        self:OnClickBtnSelect()
    end
    self.TxtSkillTitleGo = {}
    self.TxtSkillSpecificGo = {}
    self.TxtSkillName.gameObject:SetActiveEx(false)
    self.TxtSkillbrief.gameObject:SetActiveEx(false)
end

function XUiGridSwitchEnhanceSkill:Refresh(enhanceSkillId, skillLevel, isCurrent)
    self.EnhanceSkillId = enhanceSkillId

    self.SelectIcon.gameObject:SetActiveEx(isCurrent)
    self.BtnSelect.gameObject:SetActiveEx(not isCurrent)

    local gradeConfig = XMVCA.XCharacter:GetEnhanceSkillGradeDescBySkillIdAndLevel(enhanceSkillId, skillLevel)
   
    -- 技能名
    self.TxtSkillBT.text = gradeConfig.Name
    -- 技能描述
    for _, go in pairs(self.TxtSkillTitleGo) do
        go:SetActiveEx(false)
    end
    for _, go in pairs(self.TxtSkillSpecificGo) do
        go:SetActiveEx(false)
    end

    self:SetTextInfo(DescribeType.Specific, 1, gradeConfig.Intro)
end

function XUiGridSwitchEnhanceSkill:SetTextInfo(txtType, index, info)
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

function XUiGridSwitchEnhanceSkill:OnClickBtnSelect()
    XMVCA.XCharacter:CharacterSwitchEnhanceSkillRequest(self.EnhanceSkillId, self.SwitchCb)
end

return XUiGridSwitchEnhanceSkill