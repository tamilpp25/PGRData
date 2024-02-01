-- 层结算的插件分解格子，比较特殊，有两个预置在子物体里
local XUiGridRiftSettlePlugin = XClass(nil, "XUiGridRiftSettlePlugin")
local XUiRiftPluginGrid = require("XUi/XUiRift/Grid/XUiRiftPluginGrid")

function XUiGridRiftSettlePlugin:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi

    XTool.InitUiObject(self)
    self._Grid = XUiRiftPluginGrid.New(self.GridRiftCore)
end

function XUiGridRiftSettlePlugin:Refresh(decomposeData)
    local pluginId = decomposeData.PluginId
    local deCount = decomposeData.DecomposeCount
    local isShowPlugin = deCount <= 0
    local xPlugin = XDataCenter.RiftManager.GetPlugin(pluginId)
    self._Grid:Refresh(xPlugin)
    self.PanelChange.gameObject:SetActiveEx(not isShowPlugin)
    self.PanelNew.gameObject:SetActiveEx(false)
    if decomposeData.IsExtraDrop then
        self.TxtOther.gameObject:SetActiveEx(true)
        self.TxtOther.text = XUiHelper.GetText("RiftExtraDrop")
    else
        self.TxtOther.gameObject:SetActiveEx(false)
    end
end

return XUiGridRiftSettlePlugin
