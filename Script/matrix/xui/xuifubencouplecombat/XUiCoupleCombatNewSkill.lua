--技能解锁弹窗
local XUiCoupleCombatNewSkill = XLuaUiManager.Register(XLuaUi, "UiCoupleCombatNewSkill")

function XUiCoupleCombatNewSkill:OnAwake()
    self:AutoAddListener()
end

function XUiCoupleCombatNewSkill:OnStart(activeSkillList)
    self.ActiveSkillList = activeSkillList
    self:Refresh()
end

function XUiCoupleCombatNewSkill:Refresh()
    if XTool.IsTableEmpty(self.ActiveSkillList) then
        self:Close()
        return
    end

    self.CurCharacterCareerSkillId = table.remove(self.ActiveSkillList, 1)
    self.TxtName.text = XFubenCoupleCombatConfig.GetCharacterCareerSkillName(self.CurCharacterCareerSkillId)
    self.TxtActive.text = XFubenCoupleCombatConfig.GetCharacterCareerSkillDescription(self.CurCharacterCareerSkillId)   --技能说明

    local icon = XFubenCoupleCombatConfig.GetCharacterCareerSkillIcon(self.CurCharacterCareerSkillId)
    self.RImgIcon:SetRawImage(icon)

    --技能等级
    local iconLv = XFubenCoupleCombatConfig.GetCharacterCareerSkillIconLv(self.CurCharacterCareerSkillId)
    local isHasIconLv = iconLv and true or false
    if iconLv then
        self:SetUiSprite(self.ImgIconLv, iconLv)
    end
    self.Triangle.gameObject:SetActiveEx(isHasIconLv)
    self.ImgIconLv.gameObject:SetActiveEx(isHasIconLv)
end

function XUiCoupleCombatNewSkill:AutoAddListener()
    self:RegisterClickEvent(self.BtnTanchuangCloseBig, self.BtnCloseClick)
    self:RegisterClickEvent(self.BtnGo, self.OnBtnGoClick)
end

function XUiCoupleCombatNewSkill:OnBtnGoClick()
    XLuaUiManager.PopThenOpen("UiCoupleCombatSwitchSkill", self.CurCharacterCareerSkillId)
end

function XUiCoupleCombatNewSkill:BtnCloseClick()
    self:Refresh()
end