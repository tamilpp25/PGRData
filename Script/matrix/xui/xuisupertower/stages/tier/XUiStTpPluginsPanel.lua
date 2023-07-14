local Base = require("XUi/XUiSuperTower/Common/XUiSTChildPanel")
--=====================
--爬塔准备插件掉落面板
--=====================
local XUiStTpPluginsPanel = XClass(Base, "XUiStTpPluginsPanel")

function XUiStTpPluginsPanel:InitPanel()
    self.GridDrop.gameObject:SetActiveEx(false)
    self.GridGet.gameObject:SetActiveEx(false)
    self.BtnDrop.CallBack = function() self:OnClickBtnDrop() end
end

function XUiStTpPluginsPanel:OnShowPanel()
    local isStart = self.RootUi:GetIsStart()
    self.ObjDropList.gameObject:SetActiveEx(isStart)
    self.ObjGetList.gameObject:SetActiveEx(not isStart)
    if isStart then
        self:ShowDrop()
    else
        self:ShowGet()
    end
end

function XUiStTpPluginsPanel:ShowDrop()
    if not self.DropGridList then self.DropGridList = {} end
    --[[
    List
    {
        Name = name,
        PluginId = previewPluginsPreviewId[index]
    }
    ]]
    local dropList = self.RootUi.Theme:GetPluginsDropPreview()
    if dropList then
        for i = 1, 5 do
            if dropList[i] then
                if not self.DropGridList[i] then
                    local script = require("XUi/XUiSuperTower/Stages/Tier/XUiStTpDropGrid")
                    local dropGo = CS.UnityEngine.Object.Instantiate(self.GridDrop, self.PanelDropList)
                    self.DropGridList[i] = script.New(dropGo, function(grid) self:OnClickGrid(grid) end)
                end
                self.DropGridList[i]:ShowPanel()
                self.DropGridList[i]:RefreshData(dropList[i])
            else
                if self.DropGridList[i] then
                    self.DropGridList[i]:HidePanel()
                end
            end
        end
    end
end

function XUiStTpPluginsPanel:ShowGet()
    if not self.GetGridList then self.GetGridList = {} end
    --[[
    List
    {
    // 插件id
    public int Id;
    // 数量
    public int Count;
    }
    ]]
    local getList = self.RootUi.Theme:GetTierPluginInfos()
    table.sort(getList, function(infoA, infoB)
            local cfgA = XSuperTowerConfigs.GetPluginCfgById(infoA.Id)
            local cfgB = XSuperTowerConfigs.GetPluginCfgById(infoB.Id)
            if not cfgA then
                return true
            end
            if not cfgB then
                return false
            end
            if cfgA.Quality ~= cfgB.Quality then
                return cfgA.Quality < cfgB.Quality
            end
            return cfgA.Priority < cfgB.Priority
        end)
    if getList then
        local count = 1
        for _, plugin in pairs(getList) do
            for i = 1, plugin.Count do
                if not self.GetGridList[count] then
                    local script = require("XUi/XUiSuperTower/Plugins/XUiSuperTowerPluginGrid")
                    local getGo = CS.UnityEngine.Object.Instantiate(self.GridGet, self.PanelGetList)
                    self.GetGridList[count] = script.New(getGo, function(grid) self:OnClickGrid(grid) end)
                end
                self.GetGridList[count]:ShowPanel()
                self.GetGridList[count]:RefreshCfg(XSuperTowerConfigs.GetPluginCfgById(plugin.Id))
                count = count + 1
            end
        end
        for i = count + 1, #self.GetGridList do
            self.GetGridList[i]:HidePanel()
        end
        --[[ 这里是只显示相同种类插件合并的列表，且只显示前5个
        for i = 1, 5 do
            if getList[i] then
                if not self.GetGridList[i] then
                    local script = require("XUi/XUiSuperTower/Plugins/XUiSuperTowerPluginGrid")
                    local getGo = CS.UnityEngine.Object.Instantiate(self.GridGet, self.PanelGetList)
                    self.GetGridList[i] = script.New(getGo, function(grid) self:OnClickGrid(grid) end)
                end
                self.GetGridList[i]:ShowPanel()
                self.GetGridList[i]:RefreshCfg(XSuperTowerConfigs.GetPluginCfgById(getList[i].Id))
            else
                if self.GetGridList[i] then
                    self.GetGridList[i]:HidePanel()
                end
            end
        end
        ]]
    end
end

function XUiStTpPluginsPanel:OnClickBtnDrop()
    XLuaUiManager.Open("UiSuperTowerItemTip", self.RootUi.Theme, XDataCenter.SuperTowerManager.ItemType.Plugin, not self.RootUi.Theme:CheckTierIsPlaying())
end

function XUiStTpPluginsPanel:OnClickGrid(grid)
    XLuaUiManager.Open("UiSuperTowerPluginDetails", grid.Plugin, 0)
end

return XUiStTpPluginsPanel