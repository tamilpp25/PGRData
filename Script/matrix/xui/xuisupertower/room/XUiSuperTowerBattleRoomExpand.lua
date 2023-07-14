local XUiSuperTowerPluginGrid = require("XUi/XUiSuperTower/Plugins/XUiSuperTowerPluginGrid")
local XUiSuperTowerBattleRoomExpand = XClass(nil, "XUiSuperTowerBattleRoomExpand")

function XUiSuperTowerBattleRoomExpand:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.GridPlugin.gameObject:SetActiveEx(false)
    -- XTeam
    self.Team = nil
    self.GridPluginGos = {}
    self:RegisterUiEvents()
end

-- team : XTeam
function XUiSuperTowerBattleRoomExpand:SetData(team, stageId)
    self.Team = team
    self.StageId = stageId
    local superTowerManager = XDataCenter.SuperTowerManager
    local roleManager = superTowerManager.GetRoleManager()
    local stageType = superTowerManager.GetStageTypeByStageId(stageId)
    self.PanelTeam.gameObject:SetActiveEx(superTowerManager.CheckFunctionUnlockByKey(superTowerManager.FunctionName.Transfinite))
    -- 要识别冒险爬塔类型
    local isLllimitedTower = stageType == superTowerManager.StageType.LllimitedTower
    -- 等级
    local superTowerRole = nil
    local entityId = nil
    for pos = 1, 3 do
        entityId = team:GetEntityIdByTeamPos(pos)
        superTowerRole = roleManager:GetRole(entityId)
        self["BtnChar" .. pos].gameObject:SetActiveEx(superTowerRole ~= nil)
        if superTowerRole then
            local hpLeft = superTowerRole:GetHpLeft()
            self["ImgLife" .. pos].fillAmount = hpLeft / 100
            self["TxtLife" .. pos].text = string.format( "%s%%", hpLeft)
            self["TxtLevel" .. pos].text = superTowerRole:GetSuperLevel()
            self["PanelLife" .. pos].gameObject:SetActiveEx(isLllimitedTower)
            self["ImgTdIcon" .. pos].gameObject:SetActiveEx(superTowerRole:GetIsInDult())
        end
    end
    -- 超级爬塔
    self.BtnBuff01.gameObject:SetActiveEx(isLllimitedTower)
    self.BtnBuff02.gameObject:SetActiveEx(isLllimitedTower)
    -- n波和多队伍
    -- XSuperTowerPluginSlotManager
    local teamPluginSlotManager = team:GetExtraData()
    if teamPluginSlotManager and not isLllimitedTower then 
        -- 队伍插件消耗管理
        local isEmpty = teamPluginSlotManager:GetIsEmpty()
        local plugins = teamPluginSlotManager:GetPlugins(true)
        self.BtnCore.gameObject:SetActiveEx(isEmpty)
        self.PanelCore.gameObject:SetActiveEx(not isEmpty)
        for _, go in pairs(self.GridPluginGos) do
            go.gameObject:SetActiveEx(false) 
        end
        if not isEmpty then
            local go, grid, plugin
            for i = #plugins, 1, -1 do
                plugin = plugins[i]
                if plugin ~= 0 then
                    go = self.GridPluginGos[i]
                    if go == nil then 
                        go = CS.UnityEngine.Object.Instantiate(self.GridPlugin, self.PluginContent)
                        self.GridPluginGos[i] = go
                    end
                    go.gameObject:SetActiveEx(true)
                    go.transform:SetAsFirstSibling()
                    grid = XUiSuperTowerPluginGrid.New(go)
                    grid:SetClickIsShowDetail(true)
                    grid:RefreshData(plugin) 
                end
            end
        end
    else
        self.BtnCore.gameObject:SetActiveEx(false)
        self.PanelCore.gameObject:SetActiveEx(false)
    end
end

function XUiSuperTowerBattleRoomExpand:RegisterUiEvents()
    self.BtnBuff01.CallBack = function() self:OnBtnBuff01Clicked() end
    self.BtnBuff02.CallBack = function() self:OnBtnBuff02Clicked() end
    self.BtnCore.CallBack = function() self:OnBtnCoreClicked() end
    self.BtnConsume.CallBack = function() self:OnBtnCoreClicked() end
end

function XUiSuperTowerBattleRoomExpand:OnBtnBuff01Clicked()
    local theme = XDataCenter.SuperTowerManager.GetStageManager():GetThemeByStageId(self.StageId)
    XLuaUiManager.Open("UiSuperTowerItemTip", theme, XDataCenter.SuperTowerManager.ItemType.Enhance)
end

function XUiSuperTowerBattleRoomExpand:OnBtnBuff02Clicked()
    local theme = XDataCenter.SuperTowerManager.GetStageManager():GetThemeByStageId(self.StageId)
    XLuaUiManager.Open("UiSuperTowerItemTip", theme, XDataCenter.SuperTowerManager.ItemType.Plugin)
end

function XUiSuperTowerBattleRoomExpand:OnBtnCoreClicked()
    XLuaUiManager.Open("UiSuperTowerChooseCore", self.StageId)
end

return XUiSuperTowerBattleRoomExpand