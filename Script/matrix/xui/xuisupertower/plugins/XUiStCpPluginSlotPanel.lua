local Base = require("XUi/XUiSuperTower/Common/XUiSTChildPanel")
local Grid = require("XUi/XUiSuperTower/Plugins/XUiStCpSlotGrid")
local SlotScript = require("XEntity/XSuperTower/XSuperTowerPluginSlotManager")
local COST_MAX_NUM = 9
--===========================
--爬塔掉落页面 插件插槽 面板控件
--===========================
local XUiStCpPluginSlotPanel = XClass(Base, "XUiStCpPluginSlotPanel")

function XUiStCpPluginSlotPanel:InitPanel()
    self.PluginSlot = SlotScript.New()
    self.SlotIndex = {}
    COST_MAX_NUM = XSuperTowerConfigs.GetBaseConfigByKey("MaxTeamPluginCount")
    self:InitSlotGrids()
end

function XUiStCpPluginSlotPanel:InitSlotGrids()
    self.GridPos.gameObject:SetActiveEx(false)
    self.SlotGrids = {}
    for i = 1, COST_MAX_NUM do
        local gridGo = CS.UnityEngine.Object.Instantiate(self.GridPos, self.PanelContent)
        self.SlotGrids[i] = Grid.New(gridGo, i, function(grid) self:UnEquip(grid) end)
        self.SlotGrids[i]:Show()
    end
    self.RootUi.BtnClear.gameObject:SetActiveEx(false)
end

function XUiStCpPluginSlotPanel:EquipPlugin(gridIndex, plugin)
    if not plugin then return end
    local addIndex = self.PluginSlot:AddPlugin(plugin)
    self.SlotIndex[addIndex] = gridIndex
    self.SlotGrids[addIndex]:RefreshData(plugin, self.RootUi.IsStartShow)
    self:CheckSlotEmpty()
end

function XUiStCpPluginSlotPanel:SetGrids()
    local plugins = self.PluginSlot:GetPlugins()
    for index, pluginData in pairs(plugins) do
        self.SlotGrids[index]:RefreshData(pluginData)
    end
    self:CheckSlotEmpty()
end

function XUiStCpPluginSlotPanel:UnEquip(slotGrid)
    local index = slotGrid.Index
    self.RootUi:UnEquip(self.SlotIndex[index])
    self.SlotIndex[index] = 0
    self.PluginSlot:DeletePlugin(index)
    slotGrid:Reset()
    self:CheckSlotEmpty()
end

function XUiStCpPluginSlotPanel:Clear()
    for i = 1, COST_MAX_NUM do
        if self.SlotIndex[i] and self.SlotIndex[i] > 0 then
            self:UnEquip(self.SlotGrids[i])
        end
    end
    self:Confirm()
    self:CheckSlotEmpty()
end

function XUiStCpPluginSlotPanel:Confirm()
    self.RootUi.Team:UpdateExtraData(XTool.Clone(self.PluginSlot))
end

function XUiStCpPluginSlotPanel:CheckSlotEmpty()
    self.RootUi.BtnClear.gameObject:SetActiveEx(not self.PluginSlot:GetIsEmpty())
end

return XUiStCpPluginSlotPanel