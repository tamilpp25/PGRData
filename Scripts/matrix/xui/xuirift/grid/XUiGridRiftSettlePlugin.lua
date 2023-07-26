-- 层结算的插件分解格子，比较特殊，有两个预置在子物体里
local XUiGridRiftSettlePlugin = XClass(nil, "XUiGridRiftSettlePlugin")
local XUiRiftPluginGrid = require("XUi/XUiRift/Grid/XUiRiftPluginGrid")

function XUiGridRiftSettlePlugin:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi

    XTool.InitUiObject(self)
end

function XUiGridRiftSettlePlugin:Refresh(decomposeData)
    local pluginId = decomposeData.PluginId
    local deCount = decomposeData.DecomposeCount
    local isShowPlugin = deCount <= 0
    self.GridRiftCore.gameObject:SetActiveEx(isShowPlugin)
    self.Grid256New.gameObject:SetActiveEx(not isShowPlugin)
    if isShowPlugin then
        local xPlugin = XDataCenter.RiftManager.GetPlugin(pluginId)
        local grid = XUiRiftPluginGrid.New(self.GridRiftCore)
        grid:Refresh(xPlugin)
    else
        local grid = XUiGridCommon.New(self.RootUi, self.Grid256New)
        local data = 
        {
            Count = deCount,
            TemplateId = XDataCenter.ItemManager.ItemId.RiftGold,
            RewardType = 1
        }
        grid:Refresh(data)
    end
end

return XUiGridRiftSettlePlugin
