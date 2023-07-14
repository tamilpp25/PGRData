--技能切换界面的技能组图标控件
local XUiGridSkillGroup = XClass(nil, "XUiGridSkillGroup")

function XUiGridSkillGroup:Ctor(ui, rootUi, cb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)

    self.Callback = cb

    self:InitUi()
    self:AutoAddListener()
end

function XUiGridSkillGroup:InitUi()
    self.BtnSkillIcon = XUiHelper.TryGetComponent(self.Transform, "BtnSkillIcon", "XUiButton")
    self.RImgIcon = XUiHelper.TryGetComponent(self.Transform, "RImgIcon", "RawImage")
    self.Triangle = XUiHelper.TryGetComponent(self.Transform, "Triangle")
    self.ImgIconLv = XUiHelper.TryGetComponent(self.Transform, "ImgIconLv", "Image")
    self.TxtName = XUiHelper.TryGetComponent(self.Transform, "TxtName", "Text")
    self.TxtEnName = XUiHelper.TryGetComponent(self.Transform, "TxtEnName", "Text")
    self.EffectRefresh = XUiHelper.TryGetComponent(self.Transform, "EffectRefresh")
end

function XUiGridSkillGroup:RefreshData(skillType)
    self.SkillType = skillType

    self.TxtName.text = XFubenCoupleCombatConfig.GetCharacterCareerSkillGroupName(skillType)
    self.TxtEnName.text = XFubenCoupleCombatConfig.GetCharacterCareerSkillGroupEnName(skillType)

    local iconPath = XFubenCoupleCombatConfig.GetCharacterCareerSkillGroupIcon(skillType)
    self.RImgIcon:SetRawImage(iconPath)

    self:UpdateSkillLv()
end

function XUiGridSkillGroup:UpdateSkillLv(skillIds)
    local skillType = self.SkillType
    local usedSkillId = XDataCenter.FubenCoupleCombatManager.GetUsedSkillByType(skillType)
    local iconLv = usedSkillId and XFubenCoupleCombatConfig.GetCharacterCareerSkillIconLv(usedSkillId)
    local isHasIconLv = iconLv and true or false
    if self.ImgIconLv then
        if isHasIconLv then
            self.RootUi:SetUiSprite(self.ImgIconLv, iconLv)
        end
        self.ImgIconLv.gameObject:SetActiveEx(isHasIconLv)
    end
    if self.Triangle then
        self.Triangle.gameObject:SetActiveEx(isHasIconLv)
    end

    self.EffectRefresh.gameObject:SetActiveEx(false)
    if not XTool.IsTableEmpty(skillIds) then
        for _, skillId in pairs(skillIds) do
            if skillType == XFubenCoupleCombatConfig.GetCharacterCareerSkillType(skillId) then
                self.EffectRefresh.gameObject:SetActiveEx(true)
                break
            end
        end
    end
end

function XUiGridSkillGroup:AutoAddListener()
    XUiHelper.RegisterClickEvent(self, self.BtnSkillIcon, self.OnBtnSkillIconClick)
end

function XUiGridSkillGroup:OnBtnSkillIconClick()
    self.Callback(self)
    self:SetSelect(true)
end

function XUiGridSkillGroup:SetSelect(isSelect)
    self.BtnSkillIcon:SetButtonState(isSelect and CS.UiButtonState.Select or CS.UiButtonState.Normal)
end

function XUiGridSkillGroup:GetSkillType()
    return self.SkillType
end

return XUiGridSkillGroup