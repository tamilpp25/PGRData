
local XUiPivotCombatSelectDifficult = XLuaUiManager.Register(XLuaUi, "UiPivotCombatSelectDifficult")
local ABILITY_LIMIT = CS.XGame.ClientConfig:GetInt("PivotCombatAbilityLimit")
local ENHANCE_SKILL_POS = { 1, 2 } --需要检查技能位置

function XUiPivotCombatSelectDifficult:OnAwake()
    self:InitCb()
end

function XUiPivotCombatSelectDifficult:OnStart()
    
    self.TxtTitle.text = XUiHelper.GetText("PivotCombatSelectDifficultTittle")
    self.Txt.text = XUiHelper.GetText("PivotCombatSelectDifficultTips")
    --self.BtnNormal:SetName(XPivotCombatConfigs.GetDifficultName(XPivotCombatConfigs.DifficultType.Normal))
    --self.BtnHard:SetName(XPivotCombatConfigs.GetDifficultName(XPivotCombatConfigs.DifficultType.Hard))
    self.BtnNormal:SetRawImage(XPivotCombatConfigs.GetDifficultBg(XPivotCombatConfigs.DifficultType.Normal))
    self.BtnHard:SetRawImage(XPivotCombatConfigs.GetDifficultBg(XPivotCombatConfigs.DifficultType.Hard))
end

function XUiPivotCombatSelectDifficult:InitCb()
    self.BtnTanchuangClose.CallBack = function() self:Close() end
    self.BtnCancel.CallBack = function() self:Close() end
    self.BtnConfirm.CallBack = function() self:OnBtnConfirmClick() end
    self.BtnNormal.CallBack = function() self:OnSelect(XPivotCombatConfigs.DifficultType.Normal) end
    self.BtnHard.CallBack = function() self:OnSelect(XPivotCombatConfigs.DifficultType.Hard) end
end

function XUiPivotCombatSelectDifficult:OnSelect(difficultType)
    self.Difficult = difficultType
    if difficultType == XPivotCombatConfigs.DifficultType.Normal then
        self.BtnNormal:SetButtonState(CS.UiButtonState.Select)
        self.BtnHard:SetButtonState(CS.UiButtonState.Normal)
    elseif difficultType == XPivotCombatConfigs.DifficultType.Hard then
        self.BtnNormal:SetButtonState(CS.UiButtonState.Normal)
        self.BtnHard:SetButtonState(CS.UiButtonState.Select)
    end
end

function XUiPivotCombatSelectDifficult:OnBtnConfirmClick()
    if not XTool.IsNumberValid(self.Difficult) then
        XUiManager.TipText("BossSingleChooseLevelTypeEmpty")
        return
    end
    
    local OnSelect = function()
        XDataCenter.PivotCombatManager.SelectDifficultyPivotCombatRequest(self.Difficult, function()
            XLuaUiManager.PopThenOpen("UiPivotCombatMain")
        end)
    end
    if self.Difficult == XPivotCombatConfigs.DifficultType.Hard then
        local title = XUiHelper.GetText("TipTitle")
        --检测是否学习独域技能
        local spList = XMVCA.XCharacter:GetOwnCharacterList(XEnumConst.CHARACTER.CharacterType.Isomer)
        if XTool.IsTableEmpty(spList) then
            local text = XUiHelper.GetText("PivotCombatSelectDifficultNoEnhanceSkill")
            XUiManager.DialogTip(title, text, XUiManager.DialogType.Normal, nil, OnSelect)
            return
        end
        local spEnhanceSkillCount = 0
        local len = #ENHANCE_SKILL_POS
        local lockSkillCharacter = {}
        for _, character in ipairs(spList) do
            for idx, pos in ipairs(ENHANCE_SKILL_POS) do
                local group = character:GetEnhanceSkillGroupByPos(pos)
                local unlock = group and group:GetIsUnLock() or false
                if not unlock then break end
                if idx == len then
                    spEnhanceSkillCount = spEnhanceSkillCount + 1
                    table.insert(lockSkillCharacter, character)
                end
            end
        end
        if spEnhanceSkillCount <= 0 then
            local text = XUiHelper.GetText("PivotCombatSelectDifficultNoEnhanceSkill")
            XUiManager.DialogTip(title, text, XUiManager.DialogType.Normal, nil, OnSelect)
            return
        end
        --检测解锁独域技能的角色战斗力是否达到6000
        local abilityLimitCount = 0
        for _, character in ipairs(lockSkillCharacter) do
            local ability = XMVCA.XCharacter:GetCharacterAbility(character)
            if ability and ability >= ABILITY_LIMIT then
                abilityLimitCount = abilityLimitCount + 1
            end
        end
        if abilityLimitCount <= 0 then
            local text = XUiHelper.GetText("PivotCombatSelectDifficultNoAbilityLimit")
            XUiManager.DialogTip(title, text, XUiManager.DialogType.Normal, nil, OnSelect)
            return
        end
    end

    OnSelect()
end 