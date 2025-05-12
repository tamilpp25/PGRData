local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiDlcMultiPlayerExchangeGrid = require("XUi/XUiDlcMultiPlayer/XUiDlcMouseHunter/XUiDlcMultiPlayerExchangeGrid")

---@class XUiDlcMultiPlayerExchange : XLuaUi
---@field GridCharacterNew UnityEngine.RectTransform
---@field PanelScrollView UnityEngine.RectTransform
---@field BtnCancel UnityEngine.UI.Button
---@field BtnYes XUiComponent.XUiButton
---@field BtnBack XUiComponent.XUiButton
---@field BtnMainUi XUiComponent.XUiButton
---@field _Control XDlcMultiMouseHunterControl
local XUiDlcMultiPlayerExchange = XLuaUiManager.Register(XLuaUi, "UiDlcMultiPlayerExchange")

-- region 生命周期

function XUiDlcMultiPlayerExchange:OnAwake()
    XMVCA.XDlcRoom:BeginSelectCharacter()
    self._DynamicTable = nil
    self._SelectIndex = 1
    self._OriginalCharacterId = nil
    self._IsSelecting = false
    self._IsPlayedAnimation = false

    self:_InitUi()
    self:_RegisterButtonClicks()
end

function XUiDlcMultiPlayerExchange:OnStart(selectCharacter)
    self._OriginalCharacterId = selectCharacter
    self._SelectIndex = self._Control:GetSelectCharacterIndex(selectCharacter)

    self:_InitDynamicTable()
end

function XUiDlcMultiPlayerExchange:OnEnable()
    self:_RefreshDynamicTable()
    self:_RegisterListeners()
end

function XUiDlcMultiPlayerExchange:OnDisable()
    self:_RemoveListeners()
end

-- endregion

-- region 按钮事件

function XUiDlcMultiPlayerExchange:OnBtnCancelClick()
    if not self._IsSelecting then
        XEventManager.DispatchEvent(XEventId.EVENT_DLC_MOUSE_HUNTER_CHANGE_CHEARCTER, self._OriginalCharacterId)
        self:_EndSelectingAndClose()
    end
end

function XUiDlcMultiPlayerExchange:OnBtnYesClick()
    local characterId = self._DynamicTable:GetData(self._SelectIndex)

    if characterId ~= nil then
        self._IsSelecting = true
        XMVCA.XDlcRoom:SelectCharacter(characterId)
    else
        self:_EndSelectingAndClose()
    end
end

function XUiDlcMultiPlayerExchange:OnBtnTongBlackClick()
    if not self._IsSelecting then
        XEventManager.DispatchEvent(XEventId.EVENT_DLC_MOUSE_HUNTER_CHANGE_CHEARCTER, self._OriginalCharacterId)
        self:_EndSelectingAndClose()
    end
end

function XUiDlcMultiPlayerExchange:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self._DynamicTable:GetData(index)

        grid:Refresh(data, self._SelectIndex == index)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:_ChangeSelectCharacter(index, grid)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        self:_PlayOffFrameAnimation()
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        if not self._IsPlayedAnimation then
            self._Control:SetGridTransparent(grid, false, "ImgBg")
        end
    end
end

function XUiDlcMultiPlayerExchange:OnSelectCharacter(characterId)
    self._IsSelecting = false
    self:_EndSelectingAndClose()
end

-- endregion

-- region 私有方法
function XUiDlcMultiPlayerExchange:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    self:BindExitBtns(self.BtnBack, self.BtnMainUi)
    self:RegisterClickEvent(self.BtnCancel, self.OnBtnCancelClick, true)
    self:RegisterClickEvent(self.BtnYes, self.OnBtnYesClick, true)
end

function XUiDlcMultiPlayerExchange:_RegisterListeners()
    -- 在此处注册事件监听
    XEventManager.AddEventListener(XEventId.EVENT_DLC_ROOM_SELECT_CHARACTER, self.OnSelectCharacter, self)
    XEventManager.AddEventListener(XEventId.EVENT_DLC_MULTIPLAYER_MATCHING_BACK, self._EndSelectingAndClose, self)
end

function XUiDlcMultiPlayerExchange:_RemoveListeners()
    -- 在此处移除事件监听
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_ROOM_SELECT_CHARACTER, self.OnSelectCharacter, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_MULTIPLAYER_MATCHING_BACK, self._EndSelectingAndClose, self)
end

function XUiDlcMultiPlayerExchange:_InitUi()
    self.GridCharacterNew.gameObject:SetActiveEx(false)
end

function XUiDlcMultiPlayerExchange:_InitDynamicTable()
    self._DynamicTable = XDynamicTableNormal.New(self.PanelScrollView)
    self._DynamicTable:SetProxy(XUiDlcMultiPlayerExchangeGrid, self)
    self._DynamicTable:SetDelegate(self)
end

function XUiDlcMultiPlayerExchange:_RefreshDynamicTable()
    local characterIds = self._Control:GetCharacterIdList()

    self._DynamicTable:SetDataSource(characterIds)
    self._DynamicTable:ReloadDataASync(self._SelectIndex)
end

function XUiDlcMultiPlayerExchange:_RefreshModel()
    local characterId = self._DynamicTable:GetData(self._SelectIndex)

    XEventManager.DispatchEvent(XEventId.EVENT_DLC_MOUSE_HUNTER_CHANGE_CHEARCTER, characterId)
end

function XUiDlcMultiPlayerExchange:_ChangeSelectCharacter(selectIndex, selectGrid)
    local grid = self._DynamicTable:GetGridByIndex(self._SelectIndex)

    if grid then
        grid:OnSelected(false)
    end

    selectGrid:OnSelected(true)
    self._SelectIndex = selectIndex
    self:_RefreshModel()
end

function XUiDlcMultiPlayerExchange:_EndSelectingAndClose()
    XMVCA.XDlcRoom:EndSelectCharacter()
    XEventManager.DispatchEvent(XEventId.EVENT_DLC_MOUSE_HUNTER_CHANGE_UI_SHOW, false)
    self:Close()
end

function XUiDlcMultiPlayerExchange:_PlayOffFrameAnimation()
    if not self._IsPlayedAnimation then
        self._Control:PlayOffFrameAnimation(self._DynamicTable:GetGrids(), "GridCharacterNewEnable", "ImgBg", 0.05)
        self._IsPlayedAnimation = true
    end
end

-- endregion

return XUiDlcMultiPlayerExchange
