---黄金矿工排行榜主界面
---@class XUiGoldenMinerRank : XLuaUi
---@field _Control XGoldenMinerControl
local XUiGoldenMinerRank = XLuaUiManager.Register(XLuaUi, "UiGoldenMinerRank")

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
    self:SetAutoCloseInfo(self._Control:GetCurActivityEndTime(), function(isClose)
        if isClose then
            self._Control:HandleActivityEndTime()
            return
        end
    end, nil, 0)
end
--endregion

--region Ui - Refresh
function XUiGoldenMinerRank:Init()
    self._RankData = self._Control:GetRankDb()
    self:InitDynamicTable()
    self.TxtRankCount.text = XUiHelper.GetText("GoldenMinerRankTop")
end

function XUiGoldenMinerRank:Refresh()
    self:UpdateDynamicTable()
    self._MyGridRank:Refresh(self._RankData:GetMyRankPlayInfo(), true)
end
--endregion

--region Ui - RankGrid DynamicTable
function XUiGoldenMinerRank:InitDynamicTable()
    local XUiGoldenMinerRankGrid = require("XUi/XUiGoldenMiner/Rank/XUiGoldenMinerRankGrid")
    ---@type XUiGoldenMinerRankGrid
    self._MyGridRank = XUiGoldenMinerRankGrid.New(self.GridMyRank, self)
    
    self._DynamicTable = XDynamicTableNormal.New(self.RankList)
    self._DynamicTable:SetProxy(XUiGoldenMinerRankGrid, self)
    self._DynamicTable:SetDelegate(self)
    self.GridRank.gameObject:SetActiveEx(false)
end

function XUiGoldenMinerRank:UpdateDynamicTable()
    self._RankPlayInfoList = self._RankData:GetRankPlayerInfos()
    self._DynamicTable:SetDataSource(self._RankPlayInfoList)
    self._DynamicTable:ReloadDataASync()
end

---@param grid XUiGoldenMinerRankGrid
function XUiGoldenMinerRank:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local taskData = self._RankPlayInfoList[index]
        grid:Refresh(taskData)
    end
end
--endregion

--region Ui - BtnListener
function XUiGoldenMinerRank:AutoAddListener()
    self:RegisterClickEvent(self.BtnBack, self.Close)
    self:RegisterClickEvent(self.BtnMainUi, function() XLuaUiManager.RunMain() end)
    self:BindHelpBtn(self.BtnHelp, self._Control:GetClientHelpKey())
end
--endregion