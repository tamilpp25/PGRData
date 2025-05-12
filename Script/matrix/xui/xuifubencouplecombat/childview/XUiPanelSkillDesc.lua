-- v1.32 技能描述
--====================================================================
local XGridSkill  = XClass(nil, "XGridSkill")

function XGridSkill:Ctor(ui)
    self.Ui = ui
    self:InitUiObj(ui)
end

function XGridSkill:InitUiObj(ui)
    XUiHelper.InitUiClass(self, ui)
end

function XGridSkill:Refresh(skillId)
    self.RImgIcon:SetRawImage(XFubenCoupleCombatConfig.GetCharacterCareerSkillGroupIcon(skillId))
    self.TextBt.text = XFubenCoupleCombatConfig.GetCharacterCareerSkillGroupName(skillId)

    local belongCareers = XFubenCoupleCombatConfig.GetCharacterCareerSkillGroupBelongCareers(skillId)
    local text = nil
    local connent = "、"
    for _, careers in ipairs(belongCareers) do
        if not text then
            text = careers
        else
            text = text .. connent .. careers
        end
    end
    if text then
        self.Text1.text = XUiHelper.GetText("CoupleCombatSkillCareer", text)
    end
    self.Text3.text = XUiHelper.GetText("CoupleCombatSkillPassiveDesc", XFubenCoupleCombatConfig.GetCharacterCareerSkillGroupDescription(skillId))

    if not XTool.IsNumberValid(skillId) then
        return
    end
    self.Text2.text = XUiHelper.GetText("CoupleCombatSkillActiveDesc", XFubenCoupleCombatConfig.GetCharacterCareerSkillDescription(skillId))
end

function XGridSkill:SetActive(isActive)
    self.GameObject:SetActiveEx(isActive)
end

--====================================================================

local XUiPanelSkillDesc = XClass(nil, "XUiPanelSkillDesc")

function XUiPanelSkillDesc:Ctor(uiRoot, ui)
    self.UiRoot = uiRoot
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
    self:AddClickListener()

    self.SkillObjList = {}
end

function XUiPanelSkillDesc:AddClickListener()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, function() self:SetActive(false) end)
end

function XUiPanelSkillDesc:Refresh()
    -- local skillGroupTypeToSkillIdsMap = XFubenCoupleCombatConfig.GetSkillGroupTypeToSkillIdsMap()
    local usedSkillIds = XDataCenter.FubenCoupleCombatManager.GetUsedSkillIds()

    for _, skillId in pairs(usedSkillIds) do
        if not self.SkillObjList[skillId] then
            self.SkillObjList[skillId] = XGridSkill.New(XUiHelper.Instantiate(self.Skill.gameObject, self.DescContent))
            self.SkillObjList[skillId]:Refresh(skillId)
        end
        self.SkillObjList[skillId]:SetActive(true)
    end
    self.Skill.gameObject:SetActiveEx(false)
end

function XUiPanelSkillDesc:SetActive(active)
    self.GameObject:SetActiveEx(active)
    if active then
        self:Refresh()
    end
end

return XUiPanelSkillDesc