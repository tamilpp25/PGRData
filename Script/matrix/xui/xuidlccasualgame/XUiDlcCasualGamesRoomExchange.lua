local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
---@class XUiDlcCasualGamesExchange : XLuaUi
---@field GridCharacterNew UnityEngine.RectTransform
---@field PanelScrollView UnityEngine.RectTransform
---@field BtnCancel UnityEngine.UI.Button
---@field BtnYes XUiComponent.XUiButton
---@field BtnTongBlack XUiComponent.XUiButton
---@field BtnBack XUiComponent.XUiButton
---@field BtnMainUi XUiComponent.XUiButton
---@field TopControlVariable UnityEngine.RectTransform
---@field _Control XDlcCasualControl
local XUiDlcCasualGamesRoomExchange = XLuaUiManager.Register(XLuaUi, "UiDlcCasualGamesRoomExchange")
local XUiDlcCasualGamesExchangeGrid = require("XUi/XUiDlcCasualGame/XUiDlcCasualGamesExchangeGrid")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
---@type XUiDlcCasualGamesUtility
local XUiDlcCasualGamesUtility = require("XUi/XUiDlcCasualGame/XUiDlcCasualGamesUtility")

function XUiDlcCasualGamesRoomExchange:Ctor()
    self._SelectedIndex = 0
    self._DynamicTable = nil
    ---@type XDlcCasualRoom
    self._Room = nil
    self._IsSelecting = false
end

function XUiDlcCasualGamesRoomExchange:OnAwake()
    XMVCA.XDlcRoom:BeginSelectCharacter()
    self.GridCharacterNew.gameObject:SetActiveEx(false)
    self.TopControlVariable.gameObject:SetActiveEx(true)
    self.BtnMainUi.gameObject:SetActiveEx(false)
    self.BtnYes.gameObject:SetActiveEx(false)
    self.BtnCancel.gameObject:SetActiveEx(false)
    self.BtnTongBlack.gameObject:SetActiveEx(true)
    self:_RegisterButtons()
end

function XUiDlcCasualGamesRoomExchange:OnStart()
    local case = self.UiModelGo.transform:FindTransform("PanelRoleModel1")
    
    self._Room = XMVCA.XDlcRoom:GetRoomProxy()
    self._SelectedIndex = self._Control:FindCharacterIndex(self._Room:GetFightCharacterId()) or 1
    self._RoleModel = XUiPanelRoleModel.New(case, self.Name, nil, true)
    self._DynamicTable = XDynamicTableNormal.New(self.PanelScrollView)
    self._DynamicTable:SetProxy(XUiDlcCasualGamesExchangeGrid, self)
    self._DynamicTable:SetDelegate(self)
end

function XUiDlcCasualGamesRoomExchange:OnEnable()
    local character = self._Control:GetCharacterCuteById(self._Room:GetFightCharacterId())

    self:_RegisterListeners()
    self:_RefreshDynamicTable()
    self:_RefreshModel(character)
end

function XUiDlcCasualGamesRoomExchange:OnDisable()
    self:_RemoveListeners()
end

function XUiDlcCasualGamesRoomExchange:OnBtnYesClick()
    local character = self:_GetCurrentSelectCharacter()

    self._IsSelecting = true
    XMVCA.XDlcRoom:SelectCharacter(character:GetCharacterId())
    XMVCA.XDlcRoom:EndSelectCharacter()
end

function XUiDlcCasualGamesRoomExchange:OnBtnCancelClick()
    if not self._IsSelecting then
        XMVCA.XDlcRoom:EndSelectCharacter()
        self:Close()
    end
end

---@param grid XUiDlcCasualGamesExchangeGrid
function XUiDlcCasualGamesRoomExchange:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        self:_RefreshGrid(index)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        if index == self._SelectedIndex then
            return
        end

        self:_SetSelected(index, grid)
    end
end

function XUiDlcCasualGamesRoomExchange:OnSelectCharacter(characterId)
    self._IsSelecting = false
    self._Control:SetCharacter(characterId, false)
    self:Close()
end

function XUiDlcCasualGamesRoomExchange:_RefreshDynamicTable()
    self._DynamicTable:SetDataSource(self._Control:GetCuteCharacterList())
    self._DynamicTable:ReloadDataASync(self._SelectedIndex)
end

---@param grid XUiDlcCasualGamesExchangeGrid
function XUiDlcCasualGamesRoomExchange:_RefreshGrid(index)
    local character = self._DynamicTable:GetData(index)
    local isSelected = self._SelectedIndex == index
    local grid = self._DynamicTable:GetGridByIndex(index)

    if character and grid then
        grid:Refresh(character)
        grid:SetCurrentSign(isSelected)
        grid:SetSelect(isSelected)
    end
end

function XUiDlcCasualGamesRoomExchange:_SetSelected(index, grid)
    local characterList = self._Control:GetCuteCharacterList()
    local lastSelectedIndex = self._SelectedIndex
    local character = characterList[index]

    self._SelectedIndex = index
    self:_RefreshModel(character)
    self:_RefreshGrid(index)
    self:_RefreshGrid(lastSelectedIndex)
end

function XUiDlcCasualGamesRoomExchange:_RegisterButtons()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnCancelClick)
    self:RegisterClickEvent(self.BtnTongBlack, self.OnBtnYesClick)
end

function XUiDlcCasualGamesRoomExchange:_RegisterListeners()
    XEventManager.AddEventListener(XEventId.EVENT_DLC_ROOM_SELECT_CHARACTER, self.OnSelectCharacter, self)
end

function XUiDlcCasualGamesRoomExchange:_RemoveListeners()
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_ROOM_SELECT_CHARACTER, self.OnSelectCharacter, self)
end

---@param character XDlcCasualCuteCharacter
function XUiDlcCasualGamesRoomExchange:_GetCurrentSelectCharacter()
    return self._DynamicTable:GetData(self._SelectedIndex)
end

---@param character XDlcCasualCuteCharacter
function XUiDlcCasualGamesRoomExchange:_RefreshModel(character)
    self._RoleModel:ShowRoleModel()
    self._RoleModel:UpdateCuteModelByModelName(character:GetCharacterId(), nil, nil, nil, nil, character:GetModelId(), function() 
        XUiDlcCasualGamesUtility.RandomPlayAnimation(self._RoleModel)
    end, true)
end

return XUiDlcCasualGamesRoomExchange