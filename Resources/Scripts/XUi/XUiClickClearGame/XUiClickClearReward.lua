local XUiClickClearReward = XLuaUiManager.Register(XLuaUi, "UiClickClearReward")

local XUiGridClickClearReward = require("XUi/XUiClickClearGame/XUiGridClickClearReward")
function XUiClickClearReward:OnAwake()
    self.GridTreasureGrade.gameObject:SetActive(false)

    self.DynamicTable = XDynamicTableNormal.New(self.PanelTreasureGrade)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(XUiGridClickClearReward)

    CsXUiHelper.RegisterClickEvent(self.BtnTreasureBg, handler(self, self.Close))
    self.BtnTanchuangClose.CallBack = function() self:Close() end
end

function XUiClickClearReward:OnStart(rootUi)
    self.RootUi = rootUi
end

function XUiClickClearReward:SetupStarReward()
    local rewardList = XDataCenter.XClickClearGameManager.GetSortRewardList()
    if not rewardList then
        return
    end

    self.RewardList = rewardList

    self.DynamicTable:SetDataSource(rewardList)
    self.DynamicTable:ReloadDataSync()
end

function XUiClickClearReward:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid.RootUi = self
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.RewardList[index]
        if not data then return end
        grid:Refresh(data)
    end
end

function XUiClickClearReward:OnEnable()
    self:SetupStarReward()
end


function XUiClickClearReward:OnNotify(evt, ...)
    if evt == XEventId.EVENT_CLICKCLEARGAME_TAKED_REWARD then
        self:SetupStarReward()
    end
end

function XUiClickClearReward:OnGetEvents()
    return {
        XEventId.EVENT_CLICKCLEARGAME_TAKED_REWARD,
    }
end