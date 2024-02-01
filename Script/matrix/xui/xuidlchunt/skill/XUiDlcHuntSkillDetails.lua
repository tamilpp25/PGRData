---@class XUiDlcHuntSkillDetails:XLuaUi
local XUiDlcHuntSkillDetails = XLuaUiManager.Register(XLuaUi, "UiDlcHuntSkillDetails")
local XUiDlcHuntPanelSkillDetailsInfo = require("XUi/XUiDlcHunt/Skill/XUiDlcHuntPanelSkillDetailsInfo")

local SIGNAL_BAL_MEMBER = 3 --信号球技能（红黄蓝)

function XUiDlcHuntSkillDetails:OnAwake()
    self:BindExitBtns()
    -- uiDlcHunt hide panelAsset
    self.PanelAsset.gameObject:SetActiveEx(false)
    self:RegisterUiEvents()
    self.BtnTog.gameObject:SetActiveEx(false)     --信号球技能（红黄蓝)
    self.BtnSpecial.gameObject:SetActiveEx(false)
    self.SkillBtnGroups = {}
    self.SkillBtnSpecialGroups = {}               --信号球技能（红黄蓝)
    self.IsDetails = false
end

---@param character XDlcHuntCharacter
function XUiDlcHuntSkillDetails:OnStart(character, pos)
    local gridIndex = 1

    self.CharacterId = character and character:GetCharacterId() or self.CharacterId
    local skills = XDlcHuntSkillConfigs.GetData4Display(character)

    self.Skills = skills
    self.Pos = pos
    self.Skill = skills[pos]
    -- 默认显示第一个
    self.CurrentSkillSelect = gridIndex or 1

    self.SkillInfoPanel = XUiDlcHuntPanelSkillDetailsInfo.New(self.PanelSkillInfo, self)

    self:InitSkillBtn()

    self:RefreshViewData()
    self:RefreshSkillInfo()
    -- 详情默认值
    self.Toggle.isOn = XEnumConst.CHARACTER.BUTTON_SKILL_DETAILS_ACTIVE
    self:OnToggle()
end

function XUiDlcHuntSkillDetails:OnEnable()

end

function XUiDlcHuntSkillDetails:OnGetEvents()
    return {
        XEventId.EVENT_ITEM_USE,
    }
end

function XUiDlcHuntSkillDetails:OnNotify(event, ...)
    if event == XEventId.EVENT_ITEM_USE then
        self:RefreshSkillInfo()
    end
end

function XUiDlcHuntSkillDetails:InitSkillBtn()
    self:HideAllSkillBtn()
    local tabGroup = {}
    for index, subSkill in pairs(self.Skill.Skills) do
        local btn = self:GetSkillBtn(index, subSkill)
        if not btn then
            local btnGo = XUiHelper.Instantiate(self:GetSkillBtnGameObject(subSkill), self.PanelTagGroup.transform)
            btn = btnGo:GetComponent("XUiButton")
            self:SetSkillBtn(index, subSkill, btn)
        end
        btn.gameObject:SetActiveEx(true)
        btn.transform:SetAsLastSibling()
        tabGroup[index] = btn
    end
    self.PanelTagGroup:Init(tabGroup, function(tabIndex)
        self:OnClickTabCallBack(tabIndex)
    end)
end

function XUiDlcHuntSkillDetails:RefreshViewData()
    -- 技能模块名称
    self.TxtName.text = self.Skill.Name
end

function XUiDlcHuntSkillDetails:RefreshSkillInfo()
    for index, subSkill in pairs(self.Skill.Skills) do
        local btn = self:GetSkillBtn(index, subSkill)
        self:SetBtnInfo(btn, subSkill)
    end
    self.PanelTagGroup:SelectIndex(self.CurrentSkillSelect)
end

function XUiDlcHuntSkillDetails:HideAllSkillBtn()
    -- 隐藏所以按钮
    for _, btn in pairs(self.SkillBtnGroups) do
        btn.gameObject:SetActiveEx(false)
    end
    for _, btn in pairs(self.SkillBtnSpecialGroups) do
        btn.gameObject:SetActiveEx(false)
    end
end

function XUiDlcHuntSkillDetails:GetSkillBtn(index, subSkill)
    local skillType = XMVCA.XCharacter:GetSkillType(subSkill.SubSkillId)
    if skillType <= SIGNAL_BAL_MEMBER then
        return self.SkillBtnSpecialGroups[index]
    else
        return self.SkillBtnGroups[index]
    end
end

function XUiDlcHuntSkillDetails:GetSkillBtnGameObject(subSkill)
    local skillType = XMVCA.XCharacter:GetSkillType(subSkill.SubSkillId)
    if skillType <= SIGNAL_BAL_MEMBER then
        return self.BtnTog
    else
        return self.BtnSpecial
    end
end

function XUiDlcHuntSkillDetails:SetSkillBtn(index, subSkill, btn)
    local skillType = XMVCA.XCharacter:GetSkillType(subSkill.SubSkillId)
    if skillType <= SIGNAL_BAL_MEMBER then
        self.SkillBtnSpecialGroups[index] = btn
    else
        self.SkillBtnGroups[index] = btn
    end
end

function XUiDlcHuntSkillDetails:SetBtnInfo(btn, subSkillInfo)
    -- 技能Icon
    btn:SetSprite(subSkillInfo.Icon)
end

function XUiDlcHuntSkillDetails:OnClickTabCallBack(tabIndex)
    self.CurrentSkillSelect = tabIndex
    self.SkillInfoPanel:Refresh(self.CharacterId, self.Skill.Skills[tabIndex], self.IsDetails)
    self:PlayAnimation("QieHuan2")
    --XEventManager.DispatchEvent(XEventId.EVENT_GUIDE_STEP_OPEN_EVENT) -- TODO 引导
end

function XUiDlcHuntSkillDetails:GotoSkill(index)
    self.Pos = index
    self.Skill = self.Skills[index]
    -- 默认显示第一个
    self.CurrentSkillSelect = 1
    self:InitSkillBtn()
    self:RefreshSkillInfo()
    self:RefreshViewData()
    self:PlayAnimation("QieHuan1")
end

function XUiDlcHuntSkillDetails:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnNext, self.OnBtnNext)
    XUiHelper.RegisterClickEvent(self, self.BtnLast, self.OnBtnLast)
    XUiHelper.RegisterClickEvent(self, self.Toggle, self.OnToggle)
end
--region 按钮相关

-- 下一个
function XUiDlcHuntSkillDetails:OnBtnNext()
    if self.Pos then
        local nextPos = self.Pos + 1
        if nextPos > #self.Skills then
            nextPos = 1
        end
        self:GotoSkill(nextPos)
    end
end
-- 上一个
function XUiDlcHuntSkillDetails:OnBtnLast()
    if self.Pos then
        local lastPos = self.Pos - 1
        if lastPos < 1 then
            lastPos = #self.Skills
        end
        self:GotoSkill(lastPos)
    end
end

function XUiDlcHuntSkillDetails:OnToggle()
    self.IsDetails = self.Toggle.isOn
    XEnumConst.CHARACTER.BUTTON_SKILL_DETAILS_ACTIVE = self.IsDetails
    self.SkillInfoPanel:RefreshSkillDescribe(self.IsDetails)
    self:PlayAnimation("QieHuan3")
end

--endregion

--function XUiDlcHuntSkillDetails:RefreshData(clientLevel, subSkill)
--    local characterId = self.CharacterId
--    if not characterId then
--        return
--    end
--
--    self.Skills = XMVCA.XCharacter:GetCharacterSkills(characterId, clientLevel, subSkill)
--
--    self.Skill = self.Skills[self.Skill.config.Pos]
--    self:RefreshSkillData()
--end
--
--function XUiDlcHuntSkillDetails:RefreshSkillData()
--    for index, subSkill in pairs(self.Skill.subSkills) do
--        local btn = self:GetSkillBtn(index, subSkill)
--        self:SetBtnInfo(btn, subSkill)
--    end
--
--    self.SkillInfoPanel:Refresh(self.CharacterId, self.Skill.subSkills[self.CurrentSkillSelect], self.IsDetails)
--end

return XUiDlcHuntSkillDetails