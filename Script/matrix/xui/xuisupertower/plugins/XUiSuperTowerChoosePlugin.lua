--===========================
--超级爬塔选择插件页面
--===========================
local XUiSuperTowerChoosePlugin = XLuaUiManager.Register(XLuaUi, "UiSuperTowerChooseCore")

local ASSETS_KEY = "MainAssetsPanelItem"
local CHILD_PANEL = {
    Role = 1, --队伍信息
    PluginSlot = 2, --插件插槽
    PluginList = 3, --插件列表
}

local CHILD_PANEL_PATH = "XUi/XUiSuperTower/Plugins/XUiStCp"

function XUiSuperTowerChoosePlugin:OnAwake()
    XTool.InitUiObject(self)
    self:SetActivityTimeLimit()
end

function XUiSuperTowerChoosePlugin:OnStart(stageId)
    self.StageId = stageId
    self.StageType = XDataCenter.SuperTowerManager.GetStageTypeByStageId(stageId)
    self.Team = XDataCenter.SuperTowerManager.GetTeamByStageId(stageId)
    self.IsStartShow = true
    self:InitPanelAssets()
    self:InitBtns()
    self:InitChildPanels()
    self.IsStartShow = false
end

function XUiSuperTowerChoosePlugin:InitPanelAssets()
    local itemIds = {}
    for i = 1, 3 do
        local itemId = XSuperTowerConfigs.GetClientBaseConfigByKey(XDataCenter.SuperTowerManager.BaseCfgKey[ASSETS_KEY .. i], true)
        if itemId and itemId > 0 then
            table.insert(itemIds, itemId)
        end
    end
    local asset = XUiPanelAsset.New(self, self.PanelAsset, itemIds[1], itemIds[2], itemIds[3])
    asset:RegisterJumpCallList({[1] = function()
                XLuaUiManager.Open("UiTip", itemIds[1])
            end,
            [2] = function()
                XLuaUiManager.Open("UiTip", itemIds[2])
            end,
            [3] = function()
                XLuaUiManager.Open("UiTip", itemIds[3])
            end})
end

function XUiSuperTowerChoosePlugin:InitChildPanels()
    local controlScript = require("XUi/XUiSuperTower/Common/XUiSTMainPage")
    self.PanelControl = controlScript.New(self)
    self.PanelControl:RegisterChildPanels(CHILD_PANEL, CHILD_PANEL_PATH)
    self.PanelControl:ShowAllPanels()
end

function XUiSuperTowerChoosePlugin:InitBtns()
    self.BtnBack.CallBack = function() self:OnClickBack() end
    self.BtnMainUi.CallBack = function() self:OnClickMainUi() end
    self.BtnClear.CallBack = function() self:OnClickClear() end
    self.BtnInstantEquip.CallBack = function() self:OnClickInstantEquip() end
    self.BtnDetermine.CallBack = function() self:OnClickDetermine() end
end

function XUiSuperTowerChoosePlugin:OnClickBack()
    self:Close()
end

function XUiSuperTowerChoosePlugin:OnClickMainUi()
    XLuaUiManager.RunMain()
end

function XUiSuperTowerChoosePlugin:OnClickClear()
    self.PanelControl:DoFunction(CHILD_PANEL.PluginSlot, "Clear")
end

function XUiSuperTowerChoosePlugin:OnClickInstantEquip()
    self.PanelControl:DoFunction(CHILD_PANEL.PluginSlot, "Confirm")
    local stStage = XDataCenter.SuperTowerManager.GetTargetStageByStageId(self.StageId)
    self.PanelControl:DoFunction(CHILD_PANEL.PluginSlot, "Clear")
    local team = XDataCenter.SuperTowerManager.GetTeamByStageId(self.StageId)
    local teamManager = XDataCenter.SuperTowerManager.GetTeamManager()
    local isNew = teamManager:AutoSelectPlugins2Teams({team})
    if isNew then self.PanelControl:DoFunction(CHILD_PANEL.PluginList, "OnShowPanel") end
end

function XUiSuperTowerChoosePlugin:OnClickDetermine()
    self:Close()
end

function XUiSuperTowerChoosePlugin:EquipPlugin(gridIndex, plugin)
    self.PanelControl:DoFunction(CHILD_PANEL.PluginSlot, "EquipPlugin", gridIndex, plugin)
end

function XUiSuperTowerChoosePlugin:UnEquip(gridIndex)
    self.PanelControl:DoFunction(CHILD_PANEL.PluginList, "OnUnEquip", gridIndex)
end

function XUiSuperTowerChoosePlugin:OnDisable()
    XUiSuperTowerChoosePlugin.Super.OnDisable(self)
    self.PanelControl:DoFunction(CHILD_PANEL.PluginSlot, "Confirm")
end

function XUiSuperTowerChoosePlugin:SetActivityTimeLimit()
    -- 自动关闭
    local endTime = XDataCenter.SuperTowerManager.GetActivityEndTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
            if isClose then
                XDataCenter.SuperTowerManager.HandleActivityEndTime()
            end
        end)
end