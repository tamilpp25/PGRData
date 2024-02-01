local XUiTempleChangeRoleGrid = require("XUi/XUiTemple/Main/XUiTempleChangeRoleGrid")

---@class XUiTempleChangeRole : XUiNode
---@field _Control XTempleControl
local XUiTempleChangeRole = XClass(XUiNode, "UiTempleChangeRole")

function XUiTempleChangeRole:OnStart()
    ---@type XTempleUiControl
    self._UiControl = self._Control:GetUiControl()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelScrollView)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(XUiTempleChangeRoleGrid, self)
    self.GridCharacterNew.gameObject:SetActiveEx(false)
end

function XUiTempleChangeRole:OnEnable()
    self:Update()
    XEventManager.AddEventListener(XEventId.EVENT_TEMPLE_UPDATE_CHANGE_ROLE, self.OnSelected, self)
end

function XUiTempleChangeRole:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_TEMPLE_UPDATE_CHANGE_ROLE, self.OnSelected, self)
end

function XUiTempleChangeRole:OnSelected()
    XLuaUiManager.Close("UiTempleExchange")
end

function XUiTempleChangeRole:Update()
    local data = self._UiControl:GetCharacterList()
    self.DynamicTable:SetDataSource(data)
    self.DynamicTable:ReloadDataSync()
end

function XUiTempleChangeRole:OnDynamicTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Update(self.DynamicTable:GetData(index))
    end
end

return XUiTempleChangeRole