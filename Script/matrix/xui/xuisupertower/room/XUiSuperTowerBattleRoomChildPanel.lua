local XUiSuperTowerPluginGrid = require("XUi/XUiSuperTower/Plugins/XUiSuperTowerPluginGrid")
local XUiSuperTowerBattleRoomChildPanel = XClass(nil, "XUiSuperTowerBattleRoomChildPanel")

function XUiSuperTowerBattleRoomChildPanel:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    -- XTeam
    self.Team = nil
    self.StageId = nil
    self.CurrentCharacterId = nil
    self.GridPlugins = {}
    self.GridSuperTowerCore.gameObject:SetActiveEx(false)
    self:RegisterUiEvents()
    local itemIds = XSuperTowerConfigs.GetMainAssetsPanelItemIds()
    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool, self)
    XDataCenter.ItemManager.AddCountUpdateListener(itemIds, function()
            self.AssetActivityPanel:Refresh(itemIds)
        end, self.AssetActivityPanel)
    self.AssetActivityPanel:Refresh(itemIds)
end

-- team : XTeam
function XUiSuperTowerBattleRoomChildPanel:SetData(team, stageId, currentEntityId)
    self.Team = team
    self.StageId = stageId
    local currentCharacterId = XEntityHelper.GetCharacterIdByEntityId(currentEntityId)
    self.CurrentCharacterId = currentCharacterId
    local roleManager = XDataCenter.SuperTowerManager.GetRoleManager()
    local stageType = XDataCenter.SuperTowerManager.GetStageTypeByStageId(stageId)
    local isLllimitedTower = stageType == XDataCenter.SuperTowerManager.StageType.LllimitedTower
    self.GameObject:SetActiveEx(not isLllimitedTower)
    -- 爬塔不需要处理
    if isLllimitedTower then return end
    local teamPluginSlotManager = team:GetExtraData()
    -- 队伍插件消耗管理
    local plugins = teamPluginSlotManager:GetPlugins(true)
    local isEmpty = teamPluginSlotManager:GetIsEmpty()
    self.BtnCore.gameObject:SetActiveEx(isEmpty)
    self.PanelCore.gameObject:SetActiveEx(not isEmpty)
    for _, grid in pairs(self.GridPlugins) do
        grid.GameObject:SetActiveEx(false) 
    end
    if isEmpty then return end
    local go, grid, plugin, uiObj, pluginCharacterId
    for i = #plugins, 1, -1 do
        plugin = plugins[i]
        if plugin ~= 0 then
            grid = self.GridPlugins[i]
            if grid == nil then 
                go = CS.UnityEngine.Object.Instantiate(self.GridSuperTowerCore.gameObject, self.Content)
                grid = XUiSuperTowerPluginGrid.New(go)
                self.GridPlugins[i] = grid
                grid:SetClickIsShowDetail(true)
            else
                go = grid.GameObject
            end
            grid.GameObject:SetActiveEx(true)
            grid.Transform:SetAsFirstSibling()
            pluginCharacterId = plugin:GetCharacterId()
            uiObj = go:GetComponent("UiObject")
            uiObj:GetObject("ImgUp").gameObject:SetActiveEx(pluginCharacterId > 0 and currentCharacterId == pluginCharacterId)
            uiObj:GetObject("ImgDown").gameObject:SetActiveEx(pluginCharacterId > 0 and currentCharacterId ~= pluginCharacterId)
            grid:RefreshData(plugin) 
        end
    end
end

function XUiSuperTowerBattleRoomChildPanel:Refresh(currentEntityId)
    self.CurrentCharacterId = XEntityHelper.GetCharacterIdByEntityId(currentEntityId)
    local uiObj, plugin, pluginCharacterId
    for _, grid in pairs(self.GridPlugins) do
        plugin = grid:GetPlugin()
        uiObj = grid.GameObject:GetComponent("UiObject")
        pluginCharacterId = plugin:GetCharacterId()
        uiObj:GetObject("ImgUp").gameObject:SetActiveEx(pluginCharacterId > 0 and self.CurrentCharacterId == pluginCharacterId)
        uiObj:GetObject("ImgDown").gameObject:SetActiveEx(pluginCharacterId > 0 and self.CurrentCharacterId ~= pluginCharacterId)
    end
end

function XUiSuperTowerBattleRoomChildPanel:RegisterUiEvents()
    self.BtnConsume.CallBack = function() self:OnBtnCoreClicked() end
    self.BtnCore.CallBack = function() self:OnBtnCoreClicked() end
end

function XUiSuperTowerBattleRoomChildPanel:OnBtnCoreClicked()
    XLuaUiManager.Open("UiSuperTowerChooseCore", self.StageId)
end

return XUiSuperTowerBattleRoomChildPanel