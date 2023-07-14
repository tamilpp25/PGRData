--技能图标控件
local XUiGridSkill = XClass(nil, "XUiGridSkill")

function XUiGridSkill:Ctor(ui, rootUi, index)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)

    self.Index = index

    if self.BtnSkillIcon then
        XUiHelper.RegisterClickEvent(self, self.BtnSkillIcon, self.OnBtnSkillIconClick)
    end
end

function XUiGridSkill:RefreshData(careerskillId)
    self.CareerskillId = careerskillId

    --技能等级
    local iconLv = XFubenCoupleCombatConfig.GetCharacterCareerSkillIconLv(careerskillId)
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

    --图标
    if self.RImgIcon then
        local skillIcon = XFubenCoupleCombatConfig.GetCharacterCareerSkillIcon(careerskillId)
        self.RImgIcon:SetRawImage(skillIcon)
    end
end

function XUiGridSkill:OnBtnSkillIconClick()
    self.BtnSkillIcon:SetButtonState(CS.UiButtonState.Select)
    XLuaUiManager.Open("UiCoupleCombatSkillTips", self.CareerskillId, self.Index, handler(self, self.CloseSkillTipsCallback))
end

function XUiGridSkill:CloseSkillTipsCallback()
    self.BtnSkillIcon:SetButtonState(CS.UiButtonState.Normal)
end

return XUiGridSkill