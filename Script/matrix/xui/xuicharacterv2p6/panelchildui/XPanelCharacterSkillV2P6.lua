local XPanelCharacterSkillV2P6 = XClass(XUiNode, "XPanelCharacterSkillV2P6")
local XUiGridSkillItemV2P6 = require("XUi/XUiCharacterV2P6/Grid/XUiGridSkillItemV2P6")

function XPanelCharacterSkillV2P6:OnStart()
    ---@type XCharacterAgency
    local ag = XMVCA:GetAgency(ModuleId.XCharacter)
    self.CharacterAgency = ag
    self.SkillGrids = {}
    self:InitButton()
end

function XPanelCharacterSkillV2P6:InitButton()
    XUiHelper.RegisterClickEvent(self, self.BtnSkillTeach, self.OnBtnSkillTeachClick)
end

function XPanelCharacterSkillV2P6:OnBtnSkillTeachClick()
    XLuaUiManager.Open("UiPanelSkillTeach", self.Parent.CharacterId)
end

function XPanelCharacterSkillV2P6:RefreshUiShow()
    self.CharacterId = self.Parent.ParentUi.CurCharacter.Id
    self.CurCharacter = self.Parent.ParentUi.CurCharacter

    self.BtnSkillTeach.gameObject:SetActive(XPanelCharacterSkillV2P6.BUTTON_SKILL_TEACH_ACTIVE)
    self.IsShow = true
    self.GameObject:SetActive(true)
    self:ShowSkillItemPanel()
    self:UpdateSkill()
end

function XPanelCharacterSkillV2P6:UpdateSkill()
    local characterId = self.CharacterId
    local characterType = XCharacterConfigs.GetCharacterType(self.CharacterId)
    local skills = XCharacterConfigs.GetCharacterSkills(characterId)

    for i = 1, XCharacterConfigs.MAX_SHOW_SKILL_POS do
        local grid = self.SkillGrids[i]
        if not grid  then
            grid = XUiGridSkillItemV2P6.New(self["GridSkillItem" .. i], self.Parent)
            grid:SetClickCb(function ()
                self:OnGotoSkillDetail(i)
            end)
            self.SkillGrids[i] = grid
        end
        grid:UpdateNormalSkillInfo(characterId, skills[i])
    end

    local IsShowEnhanceSkill = self.CharacterAgency:CheckIsShowEnhanceSkill(self.CharacterId)
    if IsShowEnhanceSkill then
        local characterSkillGateConfig = self.CharacterAgency:GetModelCharacterSkillGate()
        for i = XCharacterConfigs.MAX_SHOW_SKILL_POS + 1, XCharacterConfigs.MAX_SHOW_SKILL_POS + 2 do
            local grid = self.SkillGrids[i]
            if not grid then
                grid = XUiGridSkillItemV2P6.New(self["GridSkillItem" .. i], self.Parent)
                grid:SetClickCb(function ()
                    self:OnGotoEnhanceSkillDetail()
                end)
                self.SkillGrids[i] = grid
            end

            grid:UpdateEnhanceSkillInfo(characterId, characterSkillGateConfig[i])
        end

        if characterType == XCharacterConfigs.CharacterType.Normal then
            self.GridSkillItem6.gameObject:SetActiveEx(true)
            self.GridSkillItem5.gameObject:SetActiveEx(false)
        else
            self.GridSkillItem5.gameObject:SetActiveEx(true)
            self.GridSkillItem6.gameObject:SetActiveEx(false)
        end
    else
        self.GridSkillItem6.gameObject:SetActiveEx(false)
        self.GridSkillItem5.gameObject:SetActiveEx(false)
    end
end

function XPanelCharacterSkillV2P6:HidePanel()
    self.BtnSkillTeach.gameObject:SetActive(XPanelCharacterSkillV2P6.BUTTON_SKILL_TEACH_ACTIVE)
    self.IsShow = false
    self.GameObject:SetActive(false)
    self:HideSkillItemPanel()
end

function XPanelCharacterSkillV2P6:HideSkillItemPanel()
    self.PanelSkillItems.gameObject:SetActive(false)
end

function XPanelCharacterSkillV2P6:ShowSkillItemPanel()
    self.PanelSkillItems.gameObject:SetActive(true)
    self.PanelSkillInfo.gameObject:SetActive(false)
    self.BtnSkillTeach.gameObject:SetActive(XPanelCharacterSkillV2P6.BUTTON_SKILL_TEACH_ACTIVE)
    self.SkillItemsQiehuan:PlayTimelineAnimation()
end

function XPanelCharacterSkillV2P6:OnGotoSkillDetail(i)
    XLuaUiManager.Open("UiSkillDetailsParentV2P6", self.CharacterId, XCharacterConfigs.SkillDetailsType.Normal, i)
end

function XPanelCharacterSkillV2P6:OnGotoEnhanceSkillDetail()
    -- 为的是将skill的第四个和 独域/跃升技能的界面连在一起。虽然他们并不是真的1-6这个顺序。但是在玩家看来是的
    XLuaUiManager.Open("UiSkillDetailsParentV2P6", self.CharacterId, XCharacterConfigs.SkillDetailsType.Enhance)
end

return XPanelCharacterSkillV2P6
