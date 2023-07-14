local XUiPanelCharPropertyOther = XLuaUiManager.Register(XLuaUi, "UiPanelCharPropertyOther")

local PANEL_INDEX = {
    All = 1,
    Level = 2,
    Grade = 3,
    Quality = 4,
    Skill = 5,
}
local DEFAULT_INDEX = 1

function XUiPanelCharPropertyOther:OnAwake()
    self:AddListener()
    -- XPartner
    self.Partner = nil
end

-- partner : XPartner
function XUiPanelCharPropertyOther:OnStart(character, equipList, weaponFashionId, assignChapterRecords, partner)
    self.Character = character
    self.EquipList = equipList
    self.WeaponFashionId = weaponFashionId
    self.AssignChapterRecords = assignChapterRecords
    self.Partner = partner

    --把服务器发来的装备数据分成武器与意识
    self.Awareness = {}
    for _, v in pairs(equipList) do
        if XDataCenter.EquipManager.IsClassifyEqualByTemplateId(v.TemplateId, XEquipConfig.Classify.Weapon) then
            self.Weapon = v
        else
            table.insert(self.Awareness, v)
        end
    end

    self:InitSceneRoot()
    self:InitChildUiInfos()
    self:InitBtnTabGroup()
end

function XUiPanelCharPropertyOther:OnEnable()
    self.PanelPropertyButtons:SelectIndex(DEFAULT_INDEX)
    self:UpdateSceneAndModel()
end

function XUiPanelCharPropertyOther:AddListener()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
end

function XUiPanelCharPropertyOther:InitSceneRoot()
    local root = self.UiModelGo.transform

    self.PanelRoleModel = root:FindTransform("PanelRoleModel")
    self.RoleModelPanel = XUiPanelRoleModel.New(self.PanelRoleModel, self.Name, nil, true, nil, true)
end

function XUiPanelCharPropertyOther:OnBtnBackClick()
    if self:RecoveryPanel() then
        return
    end
    self:Close()
end

function XUiPanelCharPropertyOther:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiPanelCharPropertyOther:InitChildUiInfos()
    --总览面板不是不是预制体
    local panelAll = XUiPanelCharAllOther.New(self.PanelOwnedInfoOther, self, self.Character, self.EquipList, self.AssignChapterRecords, self.Partner)
    self.PanelsMap = {
        [PANEL_INDEX.All] = panelAll
    }
    -- AsstPath在配表中的配置没有总览面板，所以获取其他面板路径要索引减1
    self.ChildUiInitInfos = {
        [PANEL_INDEX.All] = {
            ChildClass = XUiPanelCharAllOther,
            UiParent = self.PanelOwnedInfoOther,
        },
        [PANEL_INDEX.Level] = {
            ChildClass = XUiPanelCharLevelOther,
            UiParent = self.PanelCharLevelOther,
            AssetPath = XUiConfigs.GetComponentUrl("UiPanelCharProperty".. PANEL_INDEX.Level-1),
        },
        [PANEL_INDEX.Grade] = {
            ChildClass = XUiPanelCharGradeOther,
            UiParent = self.PanelCharGradeOther,
            AssetPath = XUiConfigs.GetComponentUrl("UiPanelCharProperty" .. PANEL_INDEX.Grade-1),
        },
        [PANEL_INDEX.Quality] = {
            ChildClass = XUiPanelCharQualityOther,
            UiParent = self.PanelCharQualityOther,
            AssetPath = XUiConfigs.GetComponentUrl("UiPanelCharProperty" .. PANEL_INDEX.Quality-1),
        },
        [PANEL_INDEX.Skill] = {
            ChildClass = XUiPanelCharSkillOther,
            UiParent = self.PanelCharSkillOther,
            AssetPath = XUiConfigs.GetComponentUrl("UiPanelCharProperty" .. PANEL_INDEX.Skill-1),
        },
    }
end

function XUiPanelCharPropertyOther:InitBtnTabGroup()
    self.BtnTabGrade.gameObject:SetActiveEx(not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.CharacterGrade))
    self.BtnTabQuality.gameObject:SetActiveEx(not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.CharacterQuality))
    self.BtnTabSkill.gameObject:SetActiveEx(not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.CharacterSkill))
    self.BtnTabLevel.gameObject:SetActiveEx(not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.CharacterLevelUp))

    local tabGroup = {
        [PANEL_INDEX.All] = self.BtnTabAll,
        [PANEL_INDEX.Level] = self.BtnTabLevel,
        [PANEL_INDEX.Grade] = self.BtnTabGrade,
        [PANEL_INDEX.Quality] = self.BtnTabQuality,
        [PANEL_INDEX.Skill] = self.BtnTabSkill,
    }
    self.PanelPropertyButtons:Init(tabGroup, function(tabIndex) self:OnClickTabCallBack(tabIndex) end)
end

function XUiPanelCharPropertyOther:OnClickTabCallBack(tabIndex)
    self.SelectedIndex = tabIndex
    self:UpdateShowPanel()
end

function XUiPanelCharPropertyOther:UpdateShowPanel()
    local index = self.SelectedIndex

    for k, panel in pairs(self.PanelsMap) do
        if k ~= index then
            panel:HidePanel()
        end
    end

    local panel = self.PanelsMap[index]
    if not panel then
        local childUiInfo = self.ChildUiInitInfos[index]
        local ui = childUiInfo.UiParent:LoadPrefab(childUiInfo.AssetPath)
        if self.SelectedIndex == PANEL_INDEX.Skill or self.SelectedIndex == PANEL_INDEX.Level then
            panel = childUiInfo.ChildClass.New(ui, self, self.Character, self.EquipList, self.AssignChapterRecords)
        else
            panel = childUiInfo.ChildClass.New(ui, self)
        end
        self.PanelsMap[index] = panel
    end
    if self.SelectedIndex == PANEL_INDEX.All then
        panel:ShowPanel(self.Character, self.Weapon, self.Awareness, self.Partner)
    elseif self.SelectedIndex == PANEL_INDEX.Skill then
        panel:ShowPanel(self.Character, self.EquipList)
    else
        panel:ShowPanel(self.Character)
    end

end

function XUiPanelCharPropertyOther:UpdateSceneAndModel()
    local sceneUrl = self:GetSceneUrl()
    local modelUrl = self:GetDefaultUiModelUrl()
    self:LoadUiScene(sceneUrl, modelUrl, nil, false)

    self.RoleModelPanel:UpdateCharacterModelOther(self.Character, self.Weapon, self.WeaponFashionId, self.PanelRoleModel, XModelManager.MODEL_UINAME.XUiCharacter, function(model)
        self.PanelDrag.Target = model.transform
    end)
end

function XUiPanelCharPropertyOther:GetSceneUrl()
    local fashionId = self.Character.FashionId or
            XCharacterConfigs.GetCharacterTemplate(self.Character.Id).DefaultNpcFashtionId
    local sceneUrl = XDataCenter.FashionManager.GetFashionSceneUrl(fashionId)
    return sceneUrl or self:GetDefaultSceneUrl()
end

function XUiPanelCharPropertyOther:RecoveryPanel()
    local skillPanel = self.PanelsMap[PANEL_INDEX.Skill]

    if skillPanel and skillPanel.SkillInfoPanel.IsShow then
        skillPanel.SkillInfoPanel:HidePanel()
        skillPanel:ShowPanel(self.Character, self.EquipList)
        return true
    end
    return false
end