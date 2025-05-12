local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiDlcMultiPlayerGiftRewardGrid = require("XUi/XUiDlcMultiPlayer/XUiDlcMouseHunter/XUiDlcMouseHunterBp/XUiDlcMultiPlayerGiftRewardGrid")

---@class XUiDlcMultiPlayerGiftReward
---@field ListReward XUiComponent.XDynamicTableNormal
---@field GridReward XUiComponent.DynamicGrid
local XUiDlcMultiPlayerGiftReward = XClass(XUiNode, "XUiDlcMultiPlayerGiftReward")

function XUiDlcMultiPlayerGiftReward:OnStart()
    self._DataSource = self._Control:GetDlcMultiplayerBPConfigs()

    self.GridReward.gameObject:SetActiveEx(false)
    self.ListRewardTable = XDynamicTableNormal.New(self.ListReward.transform)
    self.ListRewardTable:SetProxy(XUiDlcMultiPlayerGiftRewardGrid, self)
    self.ListRewardTable:SetDataSource(self._DataSource)
    self.ListRewardTable:SetDelegate(self)
end

function XUiDlcMultiPlayerGiftReward:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_DLC_MOUSE_HUNTER_REFRESH_BP_REWARDS, self._Refresh, self)
end

function XUiDlcMultiPlayerGiftReward:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_MOUSE_HUNTER_REFRESH_BP_REWARDS, self._Refresh, self)
end

function XUiDlcMultiPlayerGiftReward:_Refresh()
    self.ListRewardTable:ReloadDataSync(self._Control:GetBpLevel())
end

function XUiDlcMultiPlayerGiftReward:Show()
    self:Open()
    self:_Refresh()
end

function XUiDlcMultiPlayerGiftReward:Hide()
    self:Close()
end

function XUiDlcMultiPlayerGiftReward:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:UpdateGrid(self, self._DataSource[index])
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        self:_PlayOffFrameAnimation()
    end
end

function XUiDlcMultiPlayerGiftReward:SetRewardGridTransparent(state)
    local gridList = self.ListRewardTable:GetGrids()
    if not gridList then
        return
    end
    for _, grid in pairs(gridList) do
        self._Control:SetGridTransparent(grid, state, "PanelJuniorReward")
    end
end

function XUiDlcMultiPlayerGiftReward:_PlayOffFrameAnimation()
    self:SetRewardGridTransparent(false)
    self._Control:PlayOffFrameAnimation(self.ListRewardTable:GetGrids(), "PanelGiftGridRewardEnable", nil, 0.05, 0.2)
end

return XUiDlcMultiPlayerGiftReward