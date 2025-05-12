local XUiTempleChangeRole = require("XUi/XUiTemple/Main/XUiTempleChangeRole")

---@class XUiTempleExchange : XLuaUi
---@field _Control XTempleControl
local XUiTempleExchange = XLuaUiManager.Register(XLuaUi, "UiTempleExchange")

function XUiTempleExchange:OnAwake()
    self:BindExitBtns(self.BtnClose)
    self:BindExitBtns(self.BtnExchangeEmpty)
    ---@type XUiTempleChangeRole
    self._PanelChangeRole = XUiTempleChangeRole.New(self.PaneExchange, self)
    self._PanelChangeRole:Open()
end

function XUiTempleExchange:OnEnable()
    self:Update()
end

function XUiTempleExchange:Update()
end

return XUiTempleExchange