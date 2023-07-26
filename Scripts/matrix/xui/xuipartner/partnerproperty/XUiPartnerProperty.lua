local XUiPanelPartnerLevel = require("XUi/XUiPartner/PartnerProperty/PanelPartnerLevel/XUiPanelPartnerLevel")
local XUiPanelPartnerQuality = require("XUi/XUiPartner/PartnerProperty/PanelPartnerQuality/XUiPanelPartnerQuality")
local XUiPanelPartnerSkill = require("XUi/XUiPartner/PartnerProperty/PanelPartnerSkill/XUiPanelPartnerSkill")
local XUiPanelPartnerStory = require("XUi/XUiPartner/PartnerProperty/PanelPartnerStory/XUiPanelPartnerStory")
local XUiPartnerProperty = XLuaUiManager.Register(XLuaUi, "UiPartnerProperty")
local CSTextManagerGetText = CS.XTextManager.GetText
local DefaultIndex = 1

function XUiPartnerProperty:OnStart(base, data, index)
    self.Base = base
    self.Data = data
    self.SelectedIndex = index or DefaultIndex
    self.PanelsMap = {}
    self:InitChildUiInfos()
    self:InitBtnTabGroup()
end

function XUiPartnerProperty:OnDestroy()
   
end

function XUiPartnerProperty:OnEnable()
    
end

function XUiPartnerProperty:OnDisable()

end

function XUiPartnerProperty:InitChildUiInfos()
    self.ChildUiInitInfos = {
        [XPartnerConfigs.PriorityTabType.Level] = {
            ChildClass = XUiPanelPartnerLevel,
            UiParent = self.PanelPartnerLevel,
            AssetPath = XUiConfigs.GetComponentUrl("UiPanelPartnerLevel"),
        },
        [XPartnerConfigs.PriorityTabType.Quality] = {
            ChildClass = XUiPanelPartnerQuality,
            UiParent = self.PanelPartnerQuality,
            AssetPath = XUiConfigs.GetComponentUrl("UiPanelPartnerQuality"),
        },
        [XPartnerConfigs.PriorityTabType.Skill] = {
            ChildClass = XUiPanelPartnerSkill,
            UiParent = self.PanelPartneSkill,
            AssetPath = XUiConfigs.GetComponentUrl("UiPanelPartnerSkill"),
        },
        [XPartnerConfigs.PriorityTabType.Story] = {
            ChildClass = XUiPanelPartnerStory,
            UiParent = self.PanelPartnerStory,
            AssetPath = XUiConfigs.GetComponentUrl("UiPanelPartnerStory"),
        },
    }
end

function XUiPartnerProperty:InitBtnTabGroup()
    local tabGroup = {
        [XPartnerConfigs.PriorityTabType.Level] = self.BtnTabLevel,
        [XPartnerConfigs.PriorityTabType.Quality] = self.BtnTabQuality,
        [XPartnerConfigs.PriorityTabType.Skill] = self.BtnTabSkill,
        [XPartnerConfigs.PriorityTabType.Story] = self.BtnTabStory,
    }
    self.PanelPropertyButtons:Init(tabGroup, function(tabIndex) self:OnClickTabCallBack(tabIndex) end)
end

function XUiPartnerProperty:UpdatePanel(data)
    self.Data = data
    self.BtnTabLevel:ShowTag(self.Data:GetIsMaxBreakthrough() and self.Data:GetIsLevelMax(self.Data.BreakthroughLimit))
    self.BtnTabQuality:ShowTag(self.Data:GetIsMaxQuality())
    self.BtnTabSkill:ShowTag(self.Data:GetIsTotalSkillLevelMax())
    self.BtnTabStory:ShowTag(false)
    self.PanelPropertyButtons:SelectIndex(self.SelectedIndex)
end

function XUiPartnerProperty:OnClickTabCallBack(tabIndex)
    if tabIndex == XPartnerConfigs.PriorityTabType.Level then
        --self.PlayAnimation("LevelBegan")
        self.Base:SetCameraType(XPartnerConfigs.CameraType.Level)
    elseif tabIndex == XPartnerConfigs.PriorityTabType.Quality then
        --self.PlayAnimation("AniPanelGradesBegin")
        self.Base:SetCameraType(XPartnerConfigs.CameraType.Quality)
    elseif tabIndex == XPartnerConfigs.PriorityTabType.Skill then
        --self.PlayAnimation("AniPanelQualityBegin")
        self.Base:SetCameraType(XPartnerConfigs.CameraType.Skill)
    elseif tabIndex == XPartnerConfigs.PriorityTabType.Story then
        --self.PlayAnimation("SkillBegan")
        self.Base:SetCameraType(XPartnerConfigs.CameraType.Story)
    end
    
    self.SelectedIndex = tabIndex
    self:UpdateShowPanel(tabIndex)
end

function XUiPartnerProperty:UpdateShowPanel(tabIndex)
    for k, panel in pairs(self.PanelsMap) do
        if k ~= tabIndex then
            panel:HidePanel()
        end
    end

    local panel = self.PanelsMap[tabIndex]
    if not panel then
        local childUiInfo = self.ChildUiInitInfos[tabIndex]
        local ui = childUiInfo.UiParent:LoadPrefab(childUiInfo.AssetPath)
        panel = childUiInfo.ChildClass.New(ui, self)
        self.PanelsMap[tabIndex] = panel
    end
    panel:UpdatePanel(self.Data)
end

function XUiPartnerProperty:ShowRoleModel()
    self.Base:ShowRoleModel()
end

function XUiPartnerProperty:HideRoleModel()
    self.Base:HideRoleModel()
end

function XUiPartnerProperty:ShowTabs()
    self.PanelPropertyButtons.gameObject:SetActiveEx(true)
end

function XUiPartnerProperty:HideTabs()
    self.PanelPropertyButtons.gameObject:SetActiveEx(false)
end

function XUiPartnerProperty:GetPartnerQualityPanel()
    return self.PanelsMap[XPartnerConfigs.PriorityTabType.Quality]
end

function XUiPartnerProperty:GetPartnerSkillPanel()
    return self.PanelsMap[XPartnerConfigs.PriorityTabType.Skill]
end