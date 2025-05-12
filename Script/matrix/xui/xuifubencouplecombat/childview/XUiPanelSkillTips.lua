-- v1.32 技能描述
--====================================================================
local XGridDesc  = XClass(nil, "XGridSkill")

function XGridDesc:Ctor(ui)
    self.Ui = ui
    XUiHelper.InitUiClass(self, ui)
end

function XGridDesc:Refresh(titleTxt, descTxt)
    self.Text.text = titleTxt
    self.Text2.text = descTxt
end

function XGridDesc:SetActive(isActive)
    self.GameObject:SetActiveEx(isActive)
end

--====================================================================

local XUiPanelSkillTips = XClass(nil, "XUiPanelSkillTips")

function XUiPanelSkillTips:Ctor(uiRoot, ui)
    self.UiRoot = uiRoot
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    self.SkillCareerDesc = nil
    self.SkillActiveDesc = nil
    self.SkillPassiveDesc = nil

    XTool.InitUiObject(self)
    self:AddClickListener()
    self.BtnClosePosition = self.BtnClose.transform.position
end

function XUiPanelSkillTips:AddClickListener()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, function() self:SetActive(false) end)
end

function XUiPanelSkillTips:SetData(careerskillId, index, cb)
    self.CareerskillId = careerskillId
    self.Index = index
    self.Cb = cb
end

function XUiPanelSkillTips:Refresh()
    self:RefreshDesc()
    self:RefreshPosition()
end

--设置弹窗在界面中的位置
function XUiPanelSkillTips:RefreshPosition()
    local usedSkillIds = XDataCenter.FubenCoupleCombatManager.GetUsedSkillIds()
    local skillCount = #usedSkillIds
    local index = skillCount - self.Index + 1
    if self.UiRoot.GridSkillTemplates[index] then
        local gridSkillTransform = self.UiRoot.GridSkillTemplates[index].Transform
        local position = Vector3(
            gridSkillTransform.position.x,
            gridSkillTransform.position.y,
            self.Transform.position.z)
        self.Transform.position = position
        self.Transform.localPosition = self.Transform.localPosition -
            Vector3(self.Transform.rect.width / 2, - (self.Transform.rect.height / 2 + gridSkillTransform.rect.height / 1.5) ,0)
    end
    self.BtnClose.transform.position = self.BtnClosePosition
end

function XUiPanelSkillTips:RefreshDesc()
    --技能名称
    self.TxtName.text = XFubenCoupleCombatConfig.GetCharacterCareerSkillName(self.CareerskillId)
    self.TxtEnName.text = XFubenCoupleCombatConfig.GetCharacterCareerSkillEnName(self.CareerskillId)
    --图标
    local skillIconPath = XFubenCoupleCombatConfig.GetCharacterCareerSkillIcon(self.CareerskillId)
    self.RImgIcon:SetRawImage(skillIconPath)
    --技能等级(4期不用)
    -- local iconLv = XFubenCoupleCombatConfig.GetCharacterCareerSkillIconLv(self.CareerskillId)
    -- if iconLv then
    --     self.ImgIconLv:SetSprite(iconLv)
    --     self.Triangle.gameObject:SetActiveEx(true)
    --     self.ImgIconLv.gameObject:SetActiveEx(true)
    -- else
    --     self.Triangle.gameObject:SetActiveEx(false)
    --     self.ImgIconLv.gameObject:SetActiveEx(false)
    -- end

    --技能职业描述
    if not self.SkillCareerDesc then
        self.SkillCareerDesc = XGridDesc.New(self.Skill)
    end
    local belongCareers = XFubenCoupleCombatConfig.GetCharacterCareerSkillGroupBelongCareers(self.CareerskillId)
    local text = nil
    local connent = "、"
    for _, career in ipairs(belongCareers) do
        if not text then
            text = career
        else
            text = text .. connent .. career
        end
    end
    if text then
        self.SkillCareerDesc:Refresh(XUiHelper.GetText("CoupleCombatSkillCareerTitle"), text)
    else
        self.SkillCareerDesc:SetActive(false)
    end
    --主动技能描述
    if not self.SkillActiveDesc then
        self.SkillActiveDesc = XGridDesc.New(XUiHelper.Instantiate(self.Skill.gameObject, self.DescContent))
    end
    self.SkillActiveDesc:Refresh(XUiHelper.GetText("CoupleCombatSkillActiveTitle"), XFubenCoupleCombatConfig.GetCharacterCareerSkillDescription(self.CareerskillId))
    --被动技能描述
    if not self.SkillPassiveDesc then
        self.SkillPassiveDesc = XGridDesc.New(XUiHelper.Instantiate(self.Skill.gameObject, self.DescContent))
    end
    self.SkillPassiveDesc:Refresh(XUiHelper.GetText("CoupleCombatSkillPassiveTitle"), XFubenCoupleCombatConfig.GetCharacterCareerSkillGroupDescription(self.CareerskillId))
end

function XUiPanelSkillTips:SetActive(active)
    self.GameObject:SetActiveEx(active)
    if active then
        self:Refresh()
    else
        if self.Cb then
            self.Cb()
        end
    end
end

return XUiPanelSkillTips