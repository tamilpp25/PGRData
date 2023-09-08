local PANEL_INDEX = {
    Level = 1,
    Grade = 2,
    Quality = 3,
    Skill = 4,
    EnhanceSkill = 5,
    EnhanceSkillSp = 6,
}

local XUiPanelCharProperty = XLuaUiManager.Register(XLuaUi, "UiPanelCharProperty")
local XUiPanelCharEnhanceSkillSp = require("XUi/XUiCharacter/XUiPanelCharEnhanceSkillSp")
function XUiPanelCharProperty:OnAwake()
    self:AddListener()
end

function XUiPanelCharProperty:OnStart(parent, defaultIdx)
    self.Parent = parent
    self.SelectedIndex = defaultIdx
    self.CharacterId = self.Parent.CharacterId
    self:InitChildUiInfos()
    self:InitBtnTabGroup()
    self:RegisterOtherEvent()
    self:RegisterRedPointEvent()

    self.QualityToSkill = false
end

function XUiPanelCharProperty:OnEnable(parent, defaultIdx)
    self.CharacterId = self.Parent.CharacterId
    ---@type XCharacter
    self.CharEntity = XDataCenter.CharacterManager.GetCharacter(self.CharacterId)
    local characterType = XMVCA.XCharacter:GetCharacterType(self.CharacterId)
    self.IsSp = characterType ~= XCharacterConfigs.CharacterType.Normal
    self.Parent.PanelCharacterTypeBtns.gameObject:SetActiveEx(false)
    self.Parent.SViewCharacterList.gameObject:SetActiveEx(false)
    self.Parent:SetBtnFashionActive(false)
    self.Parent.BtnOwnedDetail.gameObject:SetActiveEx(false)
    self.Parent:SetBtnTeachingActive(false)
    if self.SelectedIndex == PANEL_INDEX.EnhanceSkill then
        local functionId = self.IsSp and XFunctionManager.FunctionName.SpCharacterEnhanceSkill or XFunctionManager.FunctionName.CharacterEnhanceSkill
        local IsShowEnhanceSkill = self.CharEntity:GetIsHasEnhanceSkill() and
                not XFunctionManager.CheckFunctionFitter(functionId)
        self.SelectedIndex = IsShowEnhanceSkill and self.SelectedIndex or PANEL_INDEX.Level
    end
    self.PanelPropertyButtons:SelectIndex(self.SelectedIndex or PANEL_INDEX.Level)
    if characterType == XCharacterConfigs.CharacterType.Normal then
        self.BtnTabEnhanceSkill:SetNameByGroup(0,CS.XTextManager.GetText("EnhanceSkillTab"))
    else
        self.BtnTabEnhanceSkill:SetNameByGroup(0,CS.XTextManager.GetText("SpEnhanceSkillTab"))
    end
    
    if self.QualityToSkill then
        self:OpenQualityPreview(self.CharacterId)
        self.QualityToSkill = false
    end

end

function XUiPanelCharProperty:OnDisable()
    self.Parent.PanelCharacterTypeBtns.gameObject:SetActiveEx(true)
    self.Parent.SViewCharacterList.gameObject:SetActiveEx(true)
    self.Parent:SetBtnFashionActive(true)
    self.Parent.BtnOwnedDetail.gameObject:SetActiveEx(true)
    self.Parent:SetBtnTeachingActive(true)

end

function XUiPanelCharProperty:OnDestroy()
    self:RemoveOtherEvent()
end

function XUiPanelCharProperty:InitChildUiInfos()
    self.PanelsMap = {}
    self.ChildUiInitInfos = {
        [PANEL_INDEX.Level] = {
            ChildClass = XUiPanelCharLevel,
            UiParent = self.PanelCharLevel,
            AssetPath = XUiConfigs.GetComponentUrl(self.Name .. PANEL_INDEX.Level),
        },
        [PANEL_INDEX.Skill] = {
            ChildClass = XUiPanelCharSkill,
            UiParent = self.PanelCharSkill,
            AssetPath = XUiConfigs.GetComponentUrl(self.Name .. PANEL_INDEX.Skill),
        },
        [PANEL_INDEX.Quality] = {
            ChildClass = XUiPanelCharQuality,
            UiParent = self.PanelCharQuality,
            AssetPath = XUiConfigs.GetComponentUrl(self.Name .. PANEL_INDEX.Quality),
        },
        [PANEL_INDEX.Grade] = {
            ChildClass = XUiPanelCharGrade,
            UiParent = self.PanelCharGrade,
            AssetPath = XUiConfigs.GetComponentUrl(self.Name .. PANEL_INDEX.Grade),
        },
        [PANEL_INDEX.EnhanceSkill] = {
            ChildClass = XUiPanelCharEnhanceSkill,
            UiParent = self.PanelCharEnhanceSkill,
            AssetPath = XUiConfigs.GetComponentUrl(self.Name .. PANEL_INDEX.EnhanceSkill),
        },
        [PANEL_INDEX.EnhanceSkillSp] = {
            ChildClass = XUiPanelCharEnhanceSkillSp,
            UiParent = self.PanelCharEnhanceSkillSp,
            AssetPath = XUiConfigs.GetComponentUrl(self.Name .. PANEL_INDEX.EnhanceSkillSp),
        },
    }
end

function XUiPanelCharProperty:InitBtnTabGroup()
    self.BtnTabGrade.gameObject:SetActiveEx(not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.CharacterGrade))
    self.BtnTabQuality.gameObject:SetActiveEx(not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.CharacterQuality))
    self.BtnTabSkill.gameObject:SetActiveEx(not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.CharacterSkill))
    self.BtnTabLevel.gameObject:SetActiveEx(not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.CharacterLevelUp))

    self.BtnTabGrade:SetDisable(not XFunctionManager.JudgeOpen(XFunctionManager.FunctionName.CharacterGrade))
    self.BtnTabQuality:SetDisable(not XFunctionManager.JudgeOpen(XFunctionManager.FunctionName.CharacterQuality))
    self.BtnTabSkill:SetDisable(not XFunctionManager.JudgeOpen(XFunctionManager.FunctionName.CharacterSkill))
    if self.IsSp then
        self.BtnTabEnhanceSkill:SetDisable(not XFunctionManager.JudgeOpen(XFunctionManager.FunctionName.SpCharacterEnhanceSkill))
    else
        self.BtnTabEnhanceSkill:SetDisable(not XFunctionManager.JudgeOpen(XFunctionManager.FunctionName.CharacterEnhanceSkill))
    end

    local tabGroup = {
        [PANEL_INDEX.Level] = self.BtnTabLevel,
        [PANEL_INDEX.Grade] = self.BtnTabGrade,
        [PANEL_INDEX.Quality] = self.BtnTabQuality,
        [PANEL_INDEX.Skill] = self.BtnTabSkill,
        [PANEL_INDEX.EnhanceSkill] = self.BtnTabEnhanceSkill,
    }
    self.PanelPropertyButtons:Init(tabGroup, function(tabIndex) self:OnClickTabCallBack(tabIndex) end)
end

function XUiPanelCharProperty:OnClickTabCallBack(tabIndex)
    if tabIndex == PANEL_INDEX.Level then
        self.Parent:PlayAnimation("LevelBegan")
        self.PreCameraType = XCharacterConfigs.XUiCharacter_Camera.LEVEL
    elseif tabIndex == PANEL_INDEX.Grade then
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.CharacterGrade) then
            return
        end
        self.Parent:PlayAnimation("AniPanelGradesBegin")
        self.PreCameraType = XCharacterConfigs.XUiCharacter_Camera.GRADE
    elseif tabIndex == PANEL_INDEX.Quality then
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.CharacterQuality) then
            return
        end
        self.Parent:PlayAnimation("AniPanelQualityBegin")
        self.PreCameraType = XCharacterConfigs.XUiCharacter_Camera.QULITY
    elseif tabIndex == PANEL_INDEX.Skill then
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.CharacterSkill) then
            return
        end
        self.PreCameraType = XCharacterConfigs.XUiCharacter_Camera.SKILL
        self.Parent:PlayAnimation("SkillBegan")
    elseif tabIndex == PANEL_INDEX.EnhanceSkill then
        if self.IsSp then
            if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.SpCharacterEnhanceSkill) then
                return
            end
        else
            if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.CharacterEnhanceSkill) then
                return
            end
        end
        self.PreCameraType = XCharacterConfigs.XUiCharacter_Camera.ENHANCESKILL
        --self.Parent:PlayAnimation("EnhanceSkillBegan")-----------TODO张爽，动画非正式
    end

    self.SelectedIndex = tabIndex
    self:UpdateShowPanel()
end

function XUiPanelCharProperty:UpdateShowPanel()
    self.Parent:UpdateCamera(self.PreCameraType)

    local index = self.SelectedIndex
    if self.IsSp and index == PANEL_INDEX.EnhanceSkill then
        index = PANEL_INDEX.EnhanceSkillSp
    end
    for k, panel in pairs(self.PanelsMap) do
        if k ~= index then
            panel:HidePanel()
        end
    end

    local panel = self.PanelsMap[index]
    if not panel then
        local childUiInfo = self.ChildUiInitInfos[index]
        local ui = childUiInfo.UiParent:LoadPrefab(childUiInfo.AssetPath)
        if index == PANEL_INDEX.EnhanceSkill or index == PANEL_INDEX.EnhanceSkillSp then
            panel = childUiInfo.ChildClass.New(ui, self, true)
        else
            panel = childUiInfo.ChildClass.New(ui, self)
        end
        self.PanelsMap[index] = panel
    end
    if index == PANEL_INDEX.EnhanceSkill or index == PANEL_INDEX.EnhanceSkillSp then
        panel:ShowPanel(self.CharacterId, true)
    else
        panel:ShowPanel(self.CharacterId)
    end
    local characterType = XMVCA.XCharacter:GetCharacterType(self.CharacterId)
    local functionId = characterType == XCharacterConfigs.CharacterType.Normal and XFunctionManager.FunctionName.CharacterEnhanceSkill or XFunctionManager.FunctionName.SpCharacterEnhanceSkill
    local IsShowEnhanceSkill = self.CharEntity:GetIsHasEnhanceSkill() and 
    not XFunctionManager.CheckFunctionFitter(functionId)
    
    self.BtnTabEnhanceSkill.gameObject:SetActiveEx(IsShowEnhanceSkill)     
    self:OnCheckRedPoint()
end

function XUiPanelCharProperty:OnCheckRedPoint()
    local characterId = self.CharacterId
    XRedPointManager.CheckByNode(self.BtnTabGrade, characterId)
    XRedPointManager.CheckByNode(self.BtnTabQuality, characterId)
    XRedPointManager.CheckByNode(self.BtnTabSkill, characterId)
    XRedPointManager.CheckByNode(self.BtnTabLevel, characterId)
    XRedPointManager.CheckByNode(self.BtnTabEnhanceSkill, characterId)
end

function XUiPanelCharProperty:RegisterOtherEvent()
    XEventManager.AddEventListener(XEventId.EVENT_ITEM_BUYASSET, self.UpdateCondition, self)
    XEventManager.AddEventListener(XEventId.EVENT_CHARACTER_INCREASE_TIP, self.ShowTip, self)
    --v1.28【角色】升阶拆分 - 从品质预览到技能详情事件注册
    XEventManager.AddEventListener(XEventId.EVENT_CHARACTER_QUALITY_SKILL, self.OpenSkillInfo, self)
end

function XUiPanelCharProperty:RegisterRedPointEvent()
    local characterId = self.CharacterId
    XRedPointManager.AddRedPointEvent(self.BtnTabGrade, self.OnCheckCharacterGradeRedPoint, self, { XRedPointConditions.Types.CONDITION_CHARACTER_GRADE }, characterId)
    XRedPointManager.AddRedPointEvent(self.BtnTabQuality, self.OnCheckCharacterQualityRedPoint, self, { XRedPointConditions.Types.CONDITION_CHARACTER_QUALITY }, characterId)
    XRedPointManager.AddRedPointEvent(self.BtnTabSkill, self.OnCheckCharacterSkillRedPoint, self, { XRedPointConditions.Types.CONDITION_CHARACTER_SKILL }, characterId)
    XRedPointManager.AddRedPointEvent(self.BtnTabLevel, self.OnCheckCharacterLevelRedPoint, self, { XRedPointConditions.Types.CONDITION_CHARACTER_LEVEL }, characterId)
    XRedPointManager.AddRedPointEvent(self.BtnTabEnhanceSkill, self.OnCheckCharacterEnhanceSkillRedPoint, self, { XRedPointConditions.Types.CONDITION_CHARACTER_ENHANCESKILL }, characterId)
end

function XUiPanelCharProperty:RemoveOtherEvent()
    XEventManager.RemoveEventListener(XEventId.EVENT_ITEM_BUYASSET, self.UpdateCondition, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_CHARACTER_INCREASE_TIP, self.ShowTip, self)
    --v1.28【角色】升阶拆分 - 从品质预览到技能详情事件注销
    XEventManager.RemoveEventListener(XEventId.EVENT_CHARACTER_QUALITY_SKILL, self.OpenSkillInfo, self)
end

function XUiPanelCharProperty:OnGetEvents()
    return {
        XEventId.EVENT_ITEM_USE,
    }
end

function XUiPanelCharProperty:OnNotify(evt, ...)
    if evt == XEventId.EVENT_ITEM_USE then
        self:UpdateCondition()
    end
end

function XUiPanelCharProperty:UpdateCondition()
    local index = self.SelectedIndex
    if self.IsSp and index == PANEL_INDEX.EnhanceSkill then
        index = PANEL_INDEX.EnhanceSkillSp
    end
    local panel = self.PanelsMap[index]
    if panel and panel.Refresh then
        panel:Refresh()
    end
    
end

function XUiPanelCharProperty:OnCheckCharacterGradeRedPoint(count)
    self.BtnTabGrade:ShowReddot(count >= 0)
end

function XUiPanelCharProperty:OnCheckCharacterQualityRedPoint(count)
    self.BtnTabQuality:ShowReddot(count >= 0)
end

function XUiPanelCharProperty:OnCheckCharacterSkillRedPoint(count)
    self.BtnTabSkill:ShowReddot(count >= 0)
end

function XUiPanelCharProperty:OnCheckCharacterLevelRedPoint(count)
    self.BtnTabLevel:ShowReddot(count >= 0)
end

function XUiPanelCharProperty:OnCheckCharacterEnhanceSkillRedPoint(count)
    self.BtnTabEnhanceSkill:ShowReddot(count >= 0)
end

function XUiPanelCharProperty:AddListener()
    self:RegisterClickEvent(self.BtnExchange, self.OnBtnExchangeClick)
end

function XUiPanelCharProperty:OnBtnExchangeClick()
    self.Parent:OpenChangeCharacterView()
end

function XUiPanelCharProperty:RecoveryPanel()
    local levelPanel = self.PanelsMap[PANEL_INDEX.Level]
    if levelPanel and levelPanel.SelectLevelItems.IsShow then
        levelPanel.SelectLevelItems:HidePanel()
        levelPanel:ShowPanel()
        self.Parent:PlayAnimation("LevelBegan")
        return true
    end
    
    local enhanceSkillPanel = self.PanelsMap[PANEL_INDEX.EnhanceSkill]
    if enhanceSkillPanel and enhanceSkillPanel:IsSelectPos() then
        enhanceSkillPanel:CleatSelectPos()
        enhanceSkillPanel:ShowPanel()
        --self.Parent:PlayAnimation("EnhanceSkillBegan")-----------TODO张爽，动画非正式
        return true
    end

    local enhanceSkillSpPanel = self.PanelsMap[PANEL_INDEX.EnhanceSkillSp]
    if enhanceSkillSpPanel and enhanceSkillSpPanel:IsSelectPos() then
        enhanceSkillSpPanel:CleatSelectPos()
        enhanceSkillSpPanel:ShowPanel()
        return true
    end

    return false
end

function XUiPanelCharProperty:ShowTip(stringDescribe, attrib, oldLevel)
    local character = XDataCenter.CharacterManager.GetCharacter(self.CharacterId)
    if oldLevel and oldLevel < character.Level then
        CS.XAudioManager.PlaySound(XSoundManager.UiBasicsMusic.UiCharacter_LevelUp)
        return
    end

    stringDescribe = stringDescribe or ""
    attrib = attrib or ""
    XLuaUiManager.Open("UiLeftPopupTip", stringDescribe, attrib)
end

--===========================================================================
--v1.28【角色】升阶拆分 - 打开品质预览
--===========================================================================
function XUiPanelCharProperty:OpenQualityPreview(characterId, star)
    self.Parent:OpenQualityPreview(characterId, star)
end

--===========================================================================
--v1.28【角色】升阶拆分 - 从品质预览到技能详情
--===========================================================================
function XUiPanelCharProperty:OpenSkillInfo(characterId, skillId)
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.CharacterSkill) then
        return
    end
    
    local skills = XCharacterConfigs.GetCharacterSkills(characterId)
    local skillGroupId, index = XCharacterConfigs.GetSkillGroupIdAndIndex(skillId)
    local skillPosToGroupIdDic = XCharacterConfigs.GetChracterSkillPosToGroupIdDic(characterId)
    for pos, group in ipairs(skillPosToGroupIdDic) do
        for gridIndex, id in ipairs(group) do
            if id == skillGroupId then
                XLuaUiManager.Open("UiSkillDetails", characterId, skills, pos, gridIndex)
                self.QualityToSkill = true
                return
            end
        end
    end
end