local XUiLuckyTenantGameGrid = require("XUi/XUiLuckyTenant/Game/XUiLuckyTenantGameGrid")

---@class XUiLuckyTenantDeleteDetail : XLuaUi
---@field _Control XLuckyTenantControl
local XUiLuckyTenantDeleteDetail = XLuaUiManager.Register(XLuaUi, "UiLuckyTenantDeleteDetail")

function XUiLuckyTenantDeleteDetail:OnAwake()
    self:BindExitBtns()
    XUiHelper.RegisterClickEvent(self, self.BtnTanchuangCloseBig, self.Close, nil, true)
    XUiHelper.RegisterClickEvent(self, self.BtnTanchuangCloseBig, self.Close, nil, true)
    XUiHelper.RegisterClickEvent(self, self.BtnCancel, self.Close, nil, true)
    XUiHelper.RegisterClickEvent(self, self.BtnDelete, self.Confirm, nil, true)
    ---@type XUiLuckyTenantGameGrid
    self._PieceGrid = XUiLuckyTenantGameGrid.New(self.GridChess, self)
end

function XUiLuckyTenantDeleteDetail:OnStart()

end

function XUiLuckyTenantDeleteDetail:OnEnable()
    self:Update()
end

function XUiLuckyTenantDeleteDetail:OnDisable()

end

function XUiLuckyTenantDeleteDetail:Update()
    self._Control:UpdateDeletePieceDetail()
    local data = self._Control:GetUiData()
    self.TxtDoc.text = data.DeletePiece.Desc
    self._PieceGrid:Update(data.DeletePiece.Piece)
end

function XUiLuckyTenantDeleteDetail:Confirm()
    self._Control:DeletePieceSelectedOnBagUi()
    --self:Close()
    XEventManager.DispatchEvent(XEventId.EVENT_LUCKY_TENANT_UPDATE_BAG)
end

return XUiLuckyTenantDeleteDetail