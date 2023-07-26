local CsXTextManagerGetText = CsXTextManagerGetText

--技能详情弹窗
local XUiCoupleCombatSkillTips = XLuaUiManager.Register(XLuaUi, "UiCoupleCombatSkillTips")

function XUiCoupleCombatSkillTips:OnAwake()
    self:AutoAddListener()
end

function XUiCoupleCombatSkillTips:OnStart(careerskillId, index, closeCallback)
    self.CloseCallback = closeCallback

    self.TxtName.text = XFubenCoupleCombatConfig.GetCharacterCareerSkillName(careerskillId)
    self.TxtEnName.text = XFubenCoupleCombatConfig.GetCharacterCareerSkillEnName(careerskillId)

    --技能等级
    local iconLv = XFubenCoupleCombatConfig.GetCharacterCareerSkillIconLv(careerskillId)
    if iconLv then
        self:SetUiSprite(self.ImgIconLv, iconLv)
        self.Triangle.gameObject:SetActiveEx(true)
        self.ImgIconLv.gameObject:SetActiveEx(true)
    else
        self.Triangle.gameObject:SetActiveEx(false)
        self.ImgIconLv.gameObject:SetActiveEx(false)
    end

    --图标
    local skillIconPath = XFubenCoupleCombatConfig.GetCharacterCareerSkillIcon(careerskillId)
    self.RImgIcon:SetRawImage(skillIconPath)

    --被动技能描述
    local skillType = XFubenCoupleCombatConfig.GetCharacterCareerSkillType(careerskillId)
    self.TxtPassive.text = XFubenCoupleCombatConfig.GetCharacterCareerSkillGroupDescription(skillType)

    --主动技能描述
    self.TxtActive.text = XFubenCoupleCombatConfig.GetCharacterCareerSkillDescription(careerskillId)

    --设置弹窗在界面中的位置
    if self["Stage" .. index] then
        self.PanelSkillTips.transform.localPosition = self["Stage" .. index].transform.localPosition
    end
end

function XUiCoupleCombatSkillTips:OnDestroy()
    if self.CloseCallback then
        self.CloseCallback()
    end
end

function XUiCoupleCombatSkillTips:AutoAddListener()
    self:RegisterClickEvent(self.BtnTanchuangCloseBig, self.Close)
end