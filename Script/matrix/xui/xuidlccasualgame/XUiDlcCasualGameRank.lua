---@class XUiDlcCasualGameRank : XLuaUi
---@field BtnBack XUiComponent.XUiButton
---@field BtnMainUi XUiComponent.XUiButton
---@field BtnHelp XUiComponent.XUiButton
---@field PanelRankingList UnityEngine.RectTransform
---@field PanelContent UnityEngine.RectTransform
---@field GridRank UnityEngine.RectTransform
---@field PanelMyRank UnityEngine.RectTransform
---@field PanelNoRank UnityEngine.RectTransform
---@field _Control XDlcCasualControl
local XUiDlcCasualGameRank = XLuaUiManager.Register(XLuaUi, "UiDlcCasualGameRank")
local XUiDlcCasualGameRankGrid = require("XUi/XUiDlcCasualGame/XUiDlcCasualGameRankGrid")
local XUiDlcCasualGameRankOwnPanel = require("XUi/XUiDlcCasualGame/XUiDlcCasualGameRankOwnPanel")

function XUiDlcCasualGameRank:Ctor()
    self._DynamicTable = nil
    self._OwnRankPanel = nil
end

function XUiDlcCasualGameRank:OnAwake()
    self.GridRank.gameObject:SetActiveEx(false)
    ---@type XUiDlcCasualGameRankOwnPanel
    self._OwnRankPanel = XUiDlcCasualGameRankOwnPanel.New(self.PanelMyRank, self)
    self:_RegisterButtons()
end

function XUiDlcCasualGameRank:OnStart()
    self:_InitDynamicTable()
end

function XUiDlcCasualGameRank:OnEnable()
    self:_RegisterListeners()
end

function XUiDlcCasualGameRank:OnDisable()
    self:_RemoveListeners()
end

---@param grid XUiDlcCasualGameRankGrid
function XUiDlcCasualGameRank:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self._DynamicTable:GetData(index)
        
        grid:Refresh(data, index)
    end
end

function XUiDlcCasualGameRank:_RegisterButtons()
    self:BindExitBtns(self.BtnBack, self.BtnMainUi)
end

function XUiDlcCasualGameRank:_InitDynamicTable()
    self._DynamicTable = XDynamicTableNormal.New(self.PanelRankingList)
    self._DynamicTable:SetProxy(XUiDlcCasualGameRankGrid, self)
    self._DynamicTable:SetDelegate(self)
end

function XUiDlcCasualGameRank:_RegisterListeners()
    XEventManager.AddEventListener(XEventId.EVENT_DLC_CASUAL_CUBE_RANK_INFO, self._RefreshRankList, self)
end

function XUiDlcCasualGameRank:_RemoveListeners()
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_CASUAL_CUBE_RANK_INFO, self._RefreshRankList, self)
end

---@param rankList XDlcCasualRank[]
function XUiDlcCasualGameRank:_RefreshRankList(ranking, totalScore, totalCount, rankList)    
    self._DynamicTable:SetDataSource(rankList)
    self._DynamicTable:ReloadDataASync()
    self._OwnRankPanel:Refresh(rankList[ranking], ranking, totalCount)
    self.PanelNoRank.gameObject:SetActiveEx(#rankList <= 0)
end

return XUiDlcCasualGameRank