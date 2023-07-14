--成员列表界面：角色展示页面
local XUiSimulatedCombatViewRole = XLuaUiManager.Register(XLuaUi, "UiSimulatedCombatViewRole")
local XUiSimulatedCombatCharProperty = require("XUi/XUiFubenSimulatedCombat/RoleList/CharacterDetail/XUiCharProperty")

local PANEL_INDEX = {
    Property = 1,
    Skill = 2,
}
local COMPONENT_NAME = "UiPanelCharProperty"
function XUiSimulatedCombatViewRole:OnAwake()

end

function XUiSimulatedCombatViewRole:OnStart(parent)
    --XRobotManager.GetRobotTemplate()
    self.Parent = parent
    self.CharacterId = self.Parent.CharacterId
    self.RobotCfg = self.Parent.RobotCfg
    self:InitChildUiInfos()
    self:InitBtnTabGroup()
    self.PanelPropertyButtons:SelectIndex(PANEL_INDEX.Property)
    self.BtnTabSkill.gameObject:SetActiveEx(false)
end

function XUiSimulatedCombatViewRole:OnEnable()
    self.CharacterId = self.Parent.CharacterId
    self.RobotCfg = self.Parent.RobotCfg
    self.Parent.CharacterList.GameObject:SetActiveEx(false)
end

function XUiSimulatedCombatViewRole:OnDisable()
    self.Parent.CharacterList.GameObject:SetActiveEx(true)
end

function XUiSimulatedCombatViewRole:InitChildUiInfos()
    self.PanelsMap = {}
    self.ChildUiInitInfos = {
        [PANEL_INDEX.Property] = {
            ChildClass = XUiSimulatedCombatCharProperty,
            UiParent = self.PanelCharLevel,
            AssetPath = XUiConfigs.GetComponentUrl(string.format(COMPONENT_NAME .. PANEL_INDEX.Property)),
        },
        --[PANEL_INDEX.Skill] = {
        --    ChildClass = XUiSimulatedCombatCharSkill,
        --    UiParent = self.PanelCharSkill,
        --    AssetPath = XUiConfigs.GetComponentUrl(string.format(COMPONENT_NAME .. PANEL_INDEX.Skill)),
        --},
    }
end

function XUiSimulatedCombatViewRole:InitBtnTabGroup()
    local tabGroup = {
        [PANEL_INDEX.Property] = self.BtnTabLevel,
        --[PANEL_INDEX.Skill] = self.BtnTabSkill,
    }
    self.PanelPropertyButtons:Init(tabGroup, function(tabIndex) self:OnClickTabCallBack(tabIndex) end)
end

function XUiSimulatedCombatViewRole:OnClickTabCallBack(tabIndex)
    if tabIndex == PANEL_INDEX.Property then
        self.Parent:PlayAnimation("LevelBegan")
        self.PreCameraType = XCharacterConfigs.XUiCharacter_Camera.LEVEL
    elseif tabIndex == PANEL_INDEX.Skill then
        self.PreCameraType = XCharacterConfigs.XUiCharacter_Camera.SKILL
        self.Parent:PlayAnimation("SkillBegan")
    end
    self.SelectedIndex = tabIndex
    self:UpdateShowPanel()
end

function XUiSimulatedCombatViewRole:UpdateShowPanel()
    self.Parent:UpdateCamera(self.PreCameraType)
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
        panel = childUiInfo.ChildClass.New(ui, self)
        self.PanelsMap[index] = panel
    end
    panel:ShowPanel(self.RobotCfg)
end