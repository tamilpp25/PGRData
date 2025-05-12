local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiPokerGuessing2PopupSelectRoleGrid = require("XUi/XUiPokerGuessing2/XUiPokerGuessing2PopupSelectRoleGrid")

---@class XUiPokerGuessing2PopupSelectRole : XLuaUi
---@field _Control XPokerGuessing2Control
local XUiPokerGuessing2PopupSelectRole = XLuaUiManager.Register(XLuaUi, "UiPokerGuessing2PopupSelectRole")

function XUiPokerGuessing2PopupSelectRole:OnAwake()
    self:BindExitBtns()
    XUiHelper.RegisterClickEvent(self, self.BtnTanchuangClose, self.Close, nil , true)
    XUiHelper.RegisterClickEvent(self, self.BtnCancel, self.Close, nil , true)
    XUiHelper.RegisterClickEvent(self, self.BtnConfirm, self.Confirm, nil , true)

    self.DynamicTable = XDynamicTableNormal.New(self.PanelSelectList)
    self.DynamicTable:SetProxy(XUiPokerGuessing2PopupSelectRoleGrid, self)
    self.DynamicTable:SetDelegate(self)

    self._SelectedCharacterId = self._Control:GetSelectedCharacterId()
    self.PanelSelectItem.gameObject:SetActiveEx(false)
end

function XUiPokerGuessing2PopupSelectRole:OnEnable()
    local dataSource = self._Control:GetCharacterList()
    self.DynamicTable:SetDataSource(dataSource)
    self.DynamicTable:ReloadDataSync(1)
end

function XUiPokerGuessing2PopupSelectRole:Confirm()
    if self._SelectedCharacterId then
        self._Control:SetSelectedCharacter(self._SelectedCharacterId)
        XEventManager.DispatchEvent(XEventId.EVENT_POKER_GUESSING2_SELECT_CHARACTER)
    end
    self:Close()
end

function XUiPokerGuessing2PopupSelectRole:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Update(self.DynamicTable:GetData(index))
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local dataSource = self.DynamicTable.DataSource
        for i = 1, #dataSource do
            dataSource[i].IsSelected = i == index
        end
        local grids = self.DynamicTable:GetGrids()
        for i, gridToUpdate in pairs(grids) do
            gridToUpdate:Update(dataSource[i])
        end
        self._SelectedCharacterId = dataSource[index].Id
    end
end

return XUiPokerGuessing2PopupSelectRole