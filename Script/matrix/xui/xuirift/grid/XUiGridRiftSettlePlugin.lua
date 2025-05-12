---@class XUiGridRiftSettlePlugin:XUiNode 层结算的插件分解格子，比较特殊，有两个预置在子物体里
---@field Parent XUiRiftSettleWin
---@field _Control XRiftControl
local XUiGridRiftSettlePlugin = XClass(XUiNode, "XUiGridRiftSettlePlugin")
local XUiRiftPluginGrid = require("XUi/XUiRift/Grid/XUiRiftPluginGrid")

function XUiGridRiftSettlePlugin:OnStart()
    self._Grid = XUiRiftPluginGrid.New(self.GridRiftCore, self)
end

function XUiGridRiftSettlePlugin:Refresh(decomposeData)
    local pluginId = decomposeData.PluginId
    local deCount = decomposeData.DecomposeCount
    local isShowPlugin = deCount <= 0
    local xPlugin = self._Control:GetPlugin(pluginId)
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
