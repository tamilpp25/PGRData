local XUiGoldenMinerRank = XLuaUiManager.Register(XLuaUi, "UiGoldenMinerRank")
local XUiGridRank = require("XUi/XUiGoldenMiner/Rank/XUiGridRank")

---黄金矿工排行榜主界面
---@class XUiGoldenMinerRank : XLuaUi
function XUiGoldenMinerRank:OnAwake()
    self:AutoAddListener()
    self:Init()
end

function XUiGoldenMinerRank:OnStart()
    self:InitTimes()
end

function XUiGoldenMinerRank:OnEnable()
    XUiGoldenMinerRank.Super.OnEnable(self)
    self:Refresh()
end


--region Activity - AutoClose
function XUiGoldenMinerRank:InitTimes()
    self:SetAutoCloseInfo(XDataCenter.GoldenMinerManager.GetActivityEndTime(), function(isClose)
        if isClose then
            XDataCenter.GoldenMinerManager.HandleActivityEndTime()
            return
        end
    end, nil, 0)
end
--endregion


--region Ui - Refresh
function XUiGoldenMinerRank:Init()
    self.MyGridRank = XUiGridRank.New(self.GridMyRank, self)
    self.RankData = XDataCenter.GoldenMinerManager.GetGoldenMinerRankData()
    self:InitDynamicTable()
    self.TxtRankCount.text = XUiHelper.GetText("GoldenMinerRankTop")
end

function XUiGoldenMinerRank:Refresh()
    self:UpdateDynamicTable()
    self.MyGridRank:Refresh(self.RankData:GetMyRankPlayInfo(), true)
end
--endregion


--region Ui - RankGrid DynamicTable
function XUiGoldenMinerRank:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.RankList)
    self.DynamicTable:SetProxy(XUiGridRank, self)
    self.DynamicTable:SetDelegate(self)
    self.GridRank.gameObject:SetActiveEx(false)
end

function XUiGoldenMinerRank:UpdateDynamicTable()
    self.RankPlayInfoList = self.RankData:GetRankPlayerInfos()
    self.DynamicTable:SetDataSource(self.RankPlayInfoList)
    self.DynamicTable:ReloadDataASync()
end

function XUiGoldenMinerRank:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local taskData = self.RankPlayInfoList[index]
        grid:Refresh(taskData)
    end
end
--endregion


--region Ui - BtnListener
function XUiGoldenMinerRank:AutoAddListener()
    self:RegisterClickEvent(self.BtnBack, self.Close)
    self:RegisterClickEvent(self.BtnMainUi, function() XLuaUiManager.RunMain() end)
    self:BindHelpBtn(self.BtnHelp, XGoldenMinerConfigs.GetHelpKey())
end
--endregion