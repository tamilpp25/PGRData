--职业技能切换列表的格子控件
local XUiSkillDetailGrid = XClass(nil, "XUiSkillDetailGrid")

function XUiSkillDetailGrid:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)

    XUiHelper.RegisterClickEvent(self, self.Btnchoice, self.OnBtnchoiceClick)
    XUiHelper.RegisterClickEvent(self, self.BtnDisableChoice, self.OnBtnDisableChoiceClick)
end

function XUiSkillDetailGrid:RefreshData(characterCareerSkillId)
    self.CharacterCareerSkillId = characterCareerSkillId
    self:UpdateSkill()
end

function XUiSkillDetailGrid:UpdateSkill()
    local characterCareerSkillId = self.CharacterCareerSkillId

    --技能图标
    local skillIcon = XFubenCoupleCombatConfig.GetCharacterCareerSkillIcon(characterCareerSkillId)
    self.RImgIconByNormal:SetRawImage(skillIcon)
    self.RImgIconBySelect:SetRawImage(skillIcon)
    self.RImgIconByDisable:SetRawImage(skillIcon)

    --技能说明
    local skillDesc = XFubenCoupleCombatConfig.GetCharacterCareerSkillDescription(characterCareerSkillId)
    self.TxtActiveByNormal.text = skillDesc
    self.TxtActiveBySelect.text = skillDesc
    self.TxtActiveByDisable.text = skillDesc

    --技能等级
    local iconLv = XFubenCoupleCombatConfig.GetCharacterCareerSkillIconLv(characterCareerSkillId)
    local isHasIconLv = iconLv and true or false
    if iconLv then
        self.RootUi:SetUiSprite(self.ImgIconLvByNormal, iconLv)
        self.RootUi:SetUiSprite(self.ImgIconLvBySelect, iconLv)
        self.RootUi:SetUiSprite(self.ImgIconLvByDisable, iconLv)
    end
    self.TriangleByNormal.gameObject:SetActiveEx(isHasIconLv)
    self.TriangleBySelect.gameObject:SetActiveEx(isHasIconLv)
    self.TriangleByDisable.gameObject:SetActiveEx(isHasIconLv)
    self.ImgIconLvByNormal.gameObject:SetActiveEx(isHasIconLv)
    self.ImgIconLvBySelect.gameObject:SetActiveEx(isHasIconLv)
    self.ImgIconLvByDisable.gameObject:SetActiveEx(isHasIconLv)

    local isUsed = XDataCenter.FubenCoupleCombatManager.IsSkillUsed(characterCareerSkillId)
    self.PanelSelect.gameObject:SetActiveEx(isUsed)

    local condition = XFubenCoupleCombatConfig.GetCharacterCareerSkillCondition(characterCareerSkillId)
    local isUnlock = not XTool.IsNumberValid(condition) and true or XConditionManager.CheckCondition(condition)
    self.PanelDisable.gameObject:SetActiveEx(not isUnlock)

    self.PanelNormal.gameObject:SetActiveEx(isUnlock and not isUsed)
end

function XUiSkillDetailGrid:OnBtnchoiceClick()
    XDataCenter.FubenCoupleCombatManager.RequestAmendCharacterCareerSkill({self.CharacterCareerSkillId})
end

function XUiSkillDetailGrid:OnBtnDisableChoiceClick()
    local characterCareerSkillId = self.CharacterCareerSkillId
    local condition = XFubenCoupleCombatConfig.GetCharacterCareerSkillCondition(characterCareerSkillId)
    local _, desc = XConditionManager.CheckCondition(condition)
    XUiManager.TipError(desc)
end

return XUiSkillDetailGrid