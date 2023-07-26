--===========================================================================
--v1.28 分阶拆分-XUiPanelQualityPreview-技能成长动态列表单元：XUiPanelQualitySkillGrid
--===========================================================================
local XUiPanelQualitySkillGrid = XClass(nil, "XUiPanelQualitySkillGrid")

function XUiPanelQualitySkillGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
    --绑定跳转技能Ui
    self.Btn.CallBack = function()
        self.RootUi:OnBtnSkillClick(XCharacterConfigs.GetCharSkillQualityApartSkillId(self.SkillData))
    end
end

function XUiPanelQualitySkillGrid:Init(parent, rootUi)
    self.Parent = parent
    self.RootUi = rootUi or parent
end

function XUiPanelQualitySkillGrid:Refresh(skillData, isLight, isNext)
    self.SkillData = skillData
    local skillQuality = XCharacterConfigs.GetCharSkillQualityApartQuality(self.SkillData)
    local skillPhase = XCharacterConfigs.GetCharSkillQualityApartPhase(self.SkillData)
    local skillName = XCharacterConfigs.GetCharSkillQualityApartName(self.SkillData)
    local skillLevel = XCharacterConfigs.GetCharSkillQualityApartLevel(self.SkillData)
    local skillIntro = XCharacterConfigs.GetCharSkillQualityApartIntro(self.SkillData)
    local skillNameText = XUiHelper.GetText("CharacterSkillNameText", XCharacterConfigs.GetCharQualityDesc(skillQuality), XTool.IsNumberValid(skillPhase) and skillPhase or "", skillName, skillLevel)
    
    self.SkillName1.text = skillNameText
    self.SkillIntro1.text = skillIntro
    self.SkillName2.text = skillNameText
    self.SkillIntro2.text = skillIntro

    self.SkillName2.gameObject:SetActiveEx(false)
    self.SkillIntro2.gameObject:SetActiveEx(false)
    if isLight then
        self.Diandian2.gameObject:SetActiveEx(true)
        self.LineSelect1.gameObject:SetActiveEx(true)
        self.LineSelect2.gameObject:SetActiveEx(true)
        self.SkillName2.gameObject:SetActiveEx(true)
        self.SkillIntro2.gameObject:SetActiveEx(true)
    elseif isNext then
        self.Diandian2.gameObject:SetActiveEx(false)
        self.LineSelect1.gameObject:SetActiveEx(true)
        self.LineSelect2.gameObject:SetActiveEx(false)
    else
        self.Diandian2.gameObject:SetActiveEx(false)
        self.LineSelect1.gameObject:SetActiveEx(false)
        self.LineSelect2.gameObject:SetActiveEx(false)
    end
end

return XUiPanelQualitySkillGrid