local XUiLuckyTenantChessGrid = require("XUi/XUiLuckyTenant/Game/XUiLuckyTenantChessGrid")

---@class XUiLuckyTenantChessSelectGrid : XUiNode
---@field _Control XLuckyTenantControl
local XUiLuckyTenantChessSelectGrid = XClass(XUiNode, "XUiLuckyTenantChessSelectGrid")

function XUiLuckyTenantChessSelectGrid:OnStart()
    ---@type XUiLuckyTenantChessGrid
    self._Detail = XUiLuckyTenantChessGrid.New(self.GirdLuckyLandlordChessDetail, self)
    XUiHelper.RegisterClickEvent(self, self.BtnReceive, self.OnClick, nil, true)
end

function XUiLuckyTenantChessSelectGrid:Update(data)
    self._Data = data
    self._Detail:Update(data)
end

function XUiLuckyTenantChessSelectGrid:OnClick()
    self._Control:SelectPiece(self._Data.Index)
end

return XUiLuckyTenantChessSelectGrid