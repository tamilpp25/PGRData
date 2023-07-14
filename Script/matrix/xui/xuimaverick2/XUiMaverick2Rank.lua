local XUiMaverick2RankGrid = require("XUi/XUiMaverick2/XUiMaverick2RankGrid")

-- 异构阵线2.0排行榜
local XUiMaverick2Rank = XLuaUiManager.Register(XLuaUi, "UiMaverick2Rank")

function XUiMaverick2Rank:OnAwake()
    self:RegisterEvent()
    self:InitDynamicTable()
    self:InitMyRankPanel()
    self:InitTimes()
    self.TxtTisp.text = CSXTextManagerGetText("MaverickRankTip")
end

function XUiMaverick2Rank:OnEnable()
    self.Super.OnEnable(self)
    self:RefreshDynamicTable()
    self:RefreshMyRank()
end

function XUiMaverick2Rank:RegisterEvent()
    self.BtnMainUi.CallBack = handler(self, function() XLuaUiManager.RunMain() end)
    self.BtnBack.CallBack = handler(self, self.Close)
end

function XUiMaverick2Rank:InitMyRankPanel()
    self.MyRank = XUiMaverick2RankGrid.New(self.GridMyRank)
end

function XUiMaverick2Rank:InitTimes()
    self:SetAutoCloseInfo(XDataCenter.Maverick2Manager.GetActivityEndTime(), function(isClose)
        if isClose then
            XLuaUiManager.RunMain()
            XUiManager.TipMsg(XUiHelper.GetText("ActivityAlreadyOver"))
        end
    end)
end

function XUiMaverick2Rank:RefreshMyRank()
    local rankInfo = XDataCenter.Maverick2Manager.GetMyRankInfo()
    self.MyRank:Refresh(rankInfo)
end

---------------------------------------- 动态列表 start ----------------------------------------
function XUiMaverick2Rank:InitDynamicTable()
    self.GridRank.gameObject:SetActive(false)
    self.DynamicTable = XDynamicTableNormal.New(self.RankList)
    self.DynamicTable:SetProxy(XUiMaverick2RankGrid)
    self.DynamicTable:SetDelegate(self)
end

function XUiMaverick2Rank:RefreshDynamicTable()
    self.DataList = XDataCenter.Maverick2Manager.GetRankingList()
    self.PanelNoRank.gameObject:SetActiveEx((not next(self.DataList)))
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataASync(1)
end

function XUiMaverick2Rank:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local rankInfo = self.DataList[index]
        rankInfo.Rank = index
        grid:Refresh(rankInfo)
    end
end
---------------------------------------- 动态列表 end ----------------------------------------