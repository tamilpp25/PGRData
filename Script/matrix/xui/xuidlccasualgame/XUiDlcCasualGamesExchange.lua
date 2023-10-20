---@class XUiDlcCasualGamesExchange : XLuaUi
---@field GridCharacterNew UnityEngine.RectTransform
---@field PanelScrollView UnityEngine.RectTransform
---@field BtnCancel UnityEngine.UI.Button
---@field BtnYes XUiComponent.XUiButton
---@field BtnTongBlack XUiComponent.XUiButton
---@field BtnBack XUiComponent.XUiButton
---@field BtnMainUi XUiComponent.XUiButton
---@field TopControlVariable UnityEngine.RectTransform
local XUiDlcCasualGamesExchange = XLuaUiManager.Register(XLuaUi, "UiDlcCasualGamesExchange")
local XUiDlcCasualGamesExchangeGrid = require("XUi/XUiDlcCasualGame/XUiDlcCasualGamesExchangeGrid")

function XUiDlcCasualGamesExchange:Ctor()
    self._SelectedIndex = 0
    self._DynamicTable = nil
end

function XUiDlcCasualGamesExchange:OnAwake()
    self.GridCharacterNew.gameObject:SetActiveEx(false)
    self.TopControlVariable.gameObject:SetActiveEx(true)
    self.BtnYes.gameObject:SetActiveEx(true)
    self.BtnTongBlack.gameObject:SetActiveEx(false)
    self._SelectedIndex = self._Control:FindCharacterIndex() or 1
    self:_RegisterButtons()
end

function XUiDlcCasualGamesExchange:OnStart()
    self._DynamicTable = XDynamicTableNormal.New(self.PanelScrollView)
    self._DynamicTable:SetProxy(XUiDlcCasualGamesExchangeGrid, self)
    self._DynamicTable:SetDelegate(self)
end

function XUiDlcCasualGamesExchange:OnEnable()
    self:_RefreshDynamicTable()
end

function XUiDlcCasualGamesExchange:OnBtnYesClick()
    self:_Close()
end

function XUiDlcCasualGamesExchange:OnBtnCancelClick()
    self:_Close()
end

function XUiDlcCasualGamesExchange:OnBtnMainUiClick()
    XEventManager.DispatchEvent(XEventId.EVENT_DLC_CASUAL_EXCHANGE_CLOSE)
    XLuaUiManager.RunMain()
end

---@param grid XUiDlcCasualGamesExchangeGrid
function XUiDlcCasualGamesExchange:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        self:_RefreshGrid(index)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        if index == self._SelectedIndex then
            return
        end

        self:_SetSelected(index, grid)
    end
end

function XUiDlcCasualGamesExchange:_Close()
    XEventManager.DispatchEvent(XEventId.EVENT_DLC_CASUAL_EXCHANGE_CLOSE)
    self:Close()
end

function XUiDlcCasualGamesExchange:_RefreshDynamicTable()
    self._DynamicTable:SetDataSource(self._Control:GetCuteCharacterList())
    self._DynamicTable:ReloadDataASync(self._SelectedIndex)
end

---@param grid XUiDlcCasualGamesExchangeGrid
function XUiDlcCasualGamesExchange:_RefreshGrid(index)
    local character = self._DynamicTable:GetData(index)
    local isSelected = self._SelectedIndex == index
    local grid = self._DynamicTable:GetGridByIndex(index)

    if character and grid then
        grid:Refresh(character)
        grid:SetCurrentSign(isSelected)
        grid:SetSelect(isSelected)
    end
end

function XUiDlcCasualGamesExchange:_SetSelected(index, grid)
    local characterList = self._Control:GetCuteCharacterList()
    local lastSelectedIndex = self._SelectedIndex
    local character = characterList[index]

    self._SelectedIndex = index
    self:_SelectedCharacter(character:GetCharacterId())
    self:_RefreshGrid(index)
    self:_RefreshGrid(lastSelectedIndex)
end

function XUiDlcCasualGamesExchange:_SelectedCharacter(characterId)
    local curCharacterId = self._Control:GetCurrentCharacterId()

    if characterId ~= curCharacterId then
        self._Control:SetCharacter(characterId, true)
    end
end

function XUiDlcCasualGamesExchange:_RegisterButtons()
    self:RegisterClickEvent(self.BtnCancel, self.OnBtnCancelClick)
    self:RegisterClickEvent(self.BtnYes, self.OnBtnYesClick)
    self:RegisterClickEvent(self.BtnBack, self.OnBtnCancelClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
end

return XUiDlcCasualGamesExchange
