local XUiLuckyTenantChessBagGrid = require("XUi/XUiLuckyTenant/Game/Bag/XUiLuckyTenantChessBagGrid")

---@class XUiLuckyTenantChessBagGroup : XUiNode
---@field _Control XLuckyTenantControl
local XUiLuckyTenantChessBagGroup = XClass(XUiNode, "XUiLuckyTenantChessBagGroup")

function XUiLuckyTenantChessBagGroup:OnStart()
    self._Grids = {}
end

---@param data XUiLuckyTenantChessBagGroupData
function XUiLuckyTenantChessBagGroup:Update(data)
    self.TxtTitle.text = data.TypeDesc
    --self.PanelGroup
    XTool.UpdateDynamicItem(self._Grids, data.Pieces, self.GridChess, XUiLuckyTenantChessBagGrid, self)
end

return XUiLuckyTenantChessBagGroup