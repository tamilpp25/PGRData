local XUiGridKillZonePluginOperate = require("XUi/XUiKillZone/XUiKillZonePlugin/XUiGridKillZonePluginOperate")

local XUiGridKillZonePluginGroup = XClass(nil, "XUiGridKillZonePluginGroup")

function XUiGridKillZonePluginGroup:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    self.PluginGrids = {}

    XTool.InitUiObject(self)

    self.GridPlugin.gameObject:SetActiveEx(false)
end

function XUiGridKillZonePluginGroup:SetClickCb(clickCb)
    self.ClickCb = clickCb
end

function XUiGridKillZonePluginGroup:Refresh(groupId)
    self.GroupId = groupId

    local name = XKillZoneConfigs.GetPluginGroupName(groupId)
    self.TxtLevelName.text = name

    local pluginIds = XKillZoneConfigs.GetPluginIdsByGroupId(groupId)
    self.PluginIds = pluginIds
    for index, pluginId in ipairs(pluginIds) do
        local grid = self.PluginGrids[index]
        if not grid then
            local go = CS.UnityEngine.Object.Instantiate(self.GridPlugin, self.PanelPlugin)
            grid = XUiGridKillZonePluginOperate.New(go, self.ClickCb)
            self.PluginGrids[index] = grid
        end

        grid:Refresh(pluginId)
        grid.GameObject:SetActiveEx(true)
    end
    for index = #pluginIds + 1, #self.PluginGrids do
        self.PluginGrids[index].GameObject:SetActiveEx(false)
    end
end

function XUiGridKillZonePluginGroup:SetSelectPlugin(selectPluginId)
    for index, pluginId in pairs(self.PluginIds) do
        local grid = self.PluginGrids[index]
        if grid then
            grid:SetSelect(pluginId == selectPluginId)
        end
    end
end

return XUiGridKillZonePluginGroup