local XUiPanelCharAllOther = require("XUi/XUiPlayerInfo/XUiPanelCharAllOther")
local XUiPanelCharSkillOther = require("XUi/XUiPlayerInfo/XUiPanelCharSkillOther")
local XUiPanelCharGradeOther = require("XUi/XUiPlayerInfo/XUiPanelCharGradeOther")
local XUiPanelCharQualityOther = require("XUi/XUiPlayerInfo/XUiPanelCharQualityOther")
local XUiPanelCharLevelOther = require("XUi/XUiPlayerInfo/XUiPanelCharLevelOther")
local XUiPanelCharPropertyOther = XLuaUiManager.Register(XLuaUi, "UiPanelCharPropertyOther")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
local XUiPanelCharEnhanceSkillSp = require("XUi/XUiCharacter/XUiPanelCharEnhanceSkillSp")

local PANEL_INDEX = {
    All = 1,
    Level = 2,
    Grade = 3,
    Quality = 4,
    Skill = 5,
    EnhanceSkill = 6,
    EnhanceSkillSp = 7,
}
local DEFAULT_INDEX = 1

function XUiPanelCharPropertyOther:OnAwake()
    self:AddListener()
    -- XPartner
    self.Partner = nil
end

-- partner : XPartner
function XUiPanelCharPropertyOther:OnStart(character, equipList, weaponFashionId, assignChapterRecords, partner, awarenessSetPositions)
    self.Character = character
    self.EquipList = equipList
    self.WeaponFashionId = weaponFashionId
    self.AssignChapterRecords = assignChapterRecords
    self.Partner = partner
    self.AwarenessSetPositions = awarenessSetPositions

    --把服务器发来的装备数据分成武器与意识
    self.Awareness = {}
    for _, v in pairs(equipList) do
        if XMVCA.XEquip:IsClassifyEqualByTemplateId(v.TemplateId, XEnumConst.EQUIP.CLASSIFY.WEAPON) then
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
    self.PanelPropertyButtons:SelectIndex(self.SelectedIndex or DEFAULT_INDEX)
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
    local panelAll = XUiPanelCharAllOther.New(self.PanelOwnedInfoOther, self, self.Character, self.EquipList, self.AssignChapterRecords, self.Partner, self.AwarenessSetPositions)
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
            AssetPath = XUiConfigs.GetComponentUrl("UiPanelCharProperty" .. PANEL_INDEX.Level - 1),
        },
        [PANEL_INDEX.Grade] = {
            ChildClass = XUiPanelCharGradeOther,
            UiParent = self.PanelCharGradeOther,
            AssetPath = XUiConfigs.GetComponentUrl("UiPanelCharProperty" .. PANEL_INDEX.Grade - 1),
        },
        [PANEL_INDEX.Quality] = {
            ChildClass = XUiPanelCharQualityOther,
            UiParent = self.PanelCharQualityOther,
            AssetPath = XUiConfigs.GetComponentUrl("UiPanelCharProperty" .. PANEL_INDEX.Quality - 1),
        },
        [PANEL_INDEX.Skill] = {
            ChildClass = XUiPanelCharSkillOther,
            UiParent = self.PanelCharSkillOther,
            AssetPath = XUiConfigs.GetComponentUrl("UiPanelCharProperty" .. PANEL_INDEX.Skill - 1),
        },
        -- [PANEL_INDEX.EnhanceSkill] = {
        --     ChildClass = XUiPanelCharEnhanceSkill,
        --     UiParent = self.PanelCharEnhanceSkillOther,
        --     AssetPath = XUiConfigs.GetComponentUrl("UiPanelCharProperty" .. PANEL_INDEX.EnhanceSkill - 1),
        -- },
        [PANEL_INDEX.EnhanceSkillSp] = {
            ChildClass = XUiPanelCharEnhanceSkillSp,
            UiParent = self.PanelCharEnhanceSpSkillOther,
            AssetPath = XUiConfigs.GetComponentUrl("UiPanelCharProperty" .. PANEL_INDEX.EnhanceSkillSp - 1),
        },
    }
end

function XUiPanelCharPropertyOther:InitBtnTabGroup()
    self.BtnTabGrade.gameObject:SetActiveEx(not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.CharacterGrade))
    self.BtnTabQuality.gameObject:SetActiveEx(not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.CharacterQuality))
    self.BtnTabSkill.gameObject:SetActiveEx(not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.CharacterSkill))
    self.BtnTabLevel.gameObject:SetActiveEx(not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.CharacterLevelUp))
    if self.Character:GetCharacterType() == XEnumConst.CHARACTER.CharacterType.Normal then
        self.BtnTabEnhanceSkill:SetNameByGroup(0,CS.XTextManager.GetText("EnhanceSkillTab"))
    elseif self.Character:GetCharacterType() == XEnumConst.CHARACTER.CharacterType.Sp then
        self.BtnTabEnhanceSkill:SetNameByGroup(0,CS.XTextManager.GetText("SpEnhanceSkillTab"))
    end
    local tabGroup = {
        [PANEL_INDEX.All] = self.BtnTabAll,
        [PANEL_INDEX.Level] = self.BtnTabLevel,
        [PANEL_INDEX.Grade] = self.BtnTabGrade,
        [PANEL_INDEX.Quality] = self.BtnTabQuality,
        [PANEL_INDEX.Skill] = self.BtnTabSkill,
        [PANEL_INDEX.EnhanceSkill] = self.BtnTabEnhanceSkill,
    }
    self.PanelPropertyButtons:Init(tabGroup, function(tabIndex) self:OnClickTabCallBack(tabIndex) end)
end

function XUiPanelCharPropertyOther:OnClickTabCallBack(tabIndex)
    self.SelectedIndex = tabIndex
    self:UpdateShowPanel()
end

function XUiPanelCharPropertyOther:UpdateShowPanel()
    local index = self.SelectedIndex
    if self.Character:GetCharacterType() == XEnumConst.CHARACTER.CharacterType.Sp and index == PANEL_INDEX.EnhanceSkill then
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
        if index == PANEL_INDEX.Skill or index == PANEL_INDEX.Level then
            panel = childUiInfo.ChildClass.New(ui, self, self.Character, self.EquipList, self.AssignChapterRecords)
        elseif index == PANEL_INDEX.EnhanceSkill or index == PANEL_INDEX.EnhanceSkillSp then
            panel = childUiInfo.ChildClass.New(ui, self, false)
        else
            panel = childUiInfo.ChildClass.New(ui, self)
        end
        self.PanelsMap[index] = panel
    end
    if self.SelectedIndex == PANEL_INDEX.All then
        panel:ShowPanel(self.Character, self.Weapon, self.Awareness, self.Partner, self.AssignChapterRecords, self.AwarenessSetPositions)
    elseif self.SelectedIndex == PANEL_INDEX.Skill then
        panel:ShowPanel(self.Character, self.EquipList)
    else
        panel:ShowPanel(self.Character)
    end

    local IsShowEnhanceSkill = self.Character:GetIsHasEnhanceSkill() and
    not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.CharacterEnhanceSkill)
    self.BtnTabEnhanceSkill.gameObject:SetActiveEx(IsShowEnhanceSkill)
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
    XMVCA.XCharacter:GetCharacterTemplate(self.Character.Id).DefaultNpcFashtionId
    local sceneUrl = XDataCenter.FashionManager.GetFashionSceneUrl(fashionId)
    return sceneUrl or self:GetDefaultSceneUrl()
end

function XUiPanelCharPropertyOther:RecoveryPanel()
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