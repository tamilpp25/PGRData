local XUiRiftRankingGrid = require("XUi/XUiRift/Grid/XUiRiftRankingGrid")

-- 大秘境排行榜
local XUiRiftRanking = XLuaUiManager.Register(XLuaUi, "UiRiftRanking")

function XUiRiftRanking:OnAwake()
    self:RegisterEvent()
    self:InitDynamicTable()
    self:InitMyRankPanel()
    self:InitTimes()
    self:InitRankGroup()
    self.TxtAndroid.gameObject:SetActive(false) --排行榜没有分安卓苹果，这里先隐藏
    self.PlayerRank.gameObject:SetActive(false)
end

function XUiRiftRanking:OnEnable()
    self.Super.OnEnable(self)

    local seasonIndex = XDataCenter.RiftManager:GetSeasonIndex()
    self.PanelTabBtn:SelectIndex(seasonIndex)
end

function XUiRiftRanking:RegisterEvent()
    self.BtnMainUi.CallBack = handler(self, function() XLuaUiManager.RunMain() end)
    self.BtnBack.CallBack = handler(self, self.Close)
end

function XUiRiftRanking:InitRankGroup()
    local index = 1
    local btns = {}
    self.BtnLockTips = {}
    local activity = XDataCenter.RiftManager.GetCurrentConfig()
    self:RefreshTemplateGrids(self.BtnRank, activity.PeriodName, self.PanelTabBtn.transform, nil, "", function(grid, data)
        table.insert(btns, grid.BtnRank)
        local isOpen = XDataCenter.RiftManager:CheckSeasonOpen(index)
        grid.BtnRank:SetButtonState(isOpen and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
        grid.BtnRank:SetNameByGroup(0, data)
        if not isOpen then
            self.BtnLockTips[index] = XUiHelper.GetText("RiftSeasonRankLock", data)
        end
        index = index + 1
    end)
    self.PanelTabBtn:Init(btns, function(index)
        self:OnTabSelected(index)
    end)
end

function XUiRiftRanking:OnTabSelected(index)
    if self.BtnLockTips[index] then
        XUiManager.TipError(self.BtnLockTips[index])
        return
    end
    if self.CurSelectIdx == index then
        return
    end
    self.CurSelectIdx = index
    XDataCenter.RiftManager.RequireRanking(function()
        self:RefreshDynamicTable()
        self:RefreshMyRank()
    end, index - 1)
end

function XUiRiftRanking:InitMyRankPanel()
    self.MyRank = XUiRiftRankingGrid.New(self.PanelMyRank)
    self.MyRank:Init()
end

function XUiRiftRanking:InitTimes()
    self:SetAutoCloseInfo(XDataCenter.RiftManager.GetActivityEndTime(), function(isClose)
        if isClose then
            XLuaUiManager.RunMain()
            XUiManager.TipMsg(XUiHelper.GetText("ActivityAlreadyOver"))
        end
    end)
end

function XUiRiftRanking:RefreshMyRank()
    local rankInfo = XDataCenter.RiftManager.GetMyRankInfo()
    self.MyRank:Refresh(rankInfo)
end

---------------------------------------- 动态列表 start ----------------------------------------
function XUiRiftRanking:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PlayerRankList)
    self.DynamicTable:SetProxy(XUiRiftRankingGrid)
    self.DynamicTable:SetDelegate(self)
end

function XUiRiftRanking:RefreshDynamicTable()
    self.DataList = XDataCenter.RiftManager.GetRankingList()
    self.PanelNoRank.gameObject:SetActiveEx((not next(self.DataList)))
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataASync(1)
end

function XUiRiftRanking:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init()
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local rankInfo = self.DataList[index]
        rankInfo.Rank = index
        grid:Refresh(rankInfo)
    end
end
---------------------------------------- 动态列表 end ----------------------------------------
