local XUiDoubleTowersRank = XLuaUiManager.Register(XLuaUi, "UiDoubleTowersRank")
local XUiGridRank = require("XUi/XUiDoubleTowers/Rank/XUiGridRank")

--动作塔防排行榜主界面
function XUiDoubleTowersRank:OnAwake()
    self:AutoAddListener()
    self:Init()
end

function XUiDoubleTowersRank:OnStart()
    self:InitTimes()
end

function XUiDoubleTowersRank:OnEnable()
    XUiDoubleTowersRank.Super.OnEnable(self)
    self:Refresh()

    self:RefreshCdTimer()
    self.ActivityEndCDSchedule = XScheduleManager.ScheduleForever(function()
        self:RefreshCdTimer()
    end, XScheduleManager.SECOND)
end

function XUiDoubleTowersRank:OnDisable()
    if self.ActivityEndCDSchedule then
        XScheduleManager.UnSchedule(self.ActivityEndCDSchedule)
    end
    self.ActivityEndCDSchedule = nil
end

function XUiDoubleTowersRank:AutoAddListener()
    
    self.BtnBack.CallBack = function() 
        self:Close()
    end
    
    self.BtnMainUi.CallBack = function() 
        XLuaUiManager.RunMain()
    end
end

function XUiDoubleTowersRank:InitTimes()
    self:SetAutoCloseInfo(XDataCenter.DoubleTowersManager.GetActivityEndTime(), function(isClose)
        if isClose then
            if self.ActivityEndCDSchedule then
                XScheduleManager.UnSchedule(self.ActivityEndCDSchedule)
            end
            self.ActivityEndCDSchedule = nil
            XDataCenter.DoubleTowersManager.HandleActivityEndTime()
            return
        end
    end, nil, 0)
end

function XUiDoubleTowersRank:Init()
    self.MyGridRank = XUiGridRank.New(self.GridMyRank, self)
    self.RankData = XDataCenter.DoubleTowersManager.GetRankData()
    self:InitDynamicTable()
    self.PanelRankInfo = {}
    XTool.InitUiObjectByUi(self.PanelRankInfo, self.PanelBossRankInfo)
    self.BtnHelp.gameObject:SetActiveEx(false)
end

function XUiDoubleTowersRank:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PlayerRankList)
    self.DynamicTable:SetProxy(XUiGridRank, self)
    self.DynamicTable:SetDelegate(self)
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
end

function XUiDoubleTowersRank:UpdateDynamicTable()
    self.RankPlayInfoList = self.RankData:GetRankPlayerInfos()
    local isEmptyTb = XTool.IsTableEmpty(self.RankPlayInfoList)
    self.PanelRankInfo.PanelNoRank.gameObject:SetActiveEx(isEmptyTb)
    self.GridMyRank.gameObject:SetActiveEx(not isEmptyTb)
    if isEmptyTb then return end
    self.DynamicTable:SetDataSource(self.RankPlayInfoList)
    self.DynamicTable:ReloadDataASync()
end

function XUiDoubleTowersRank:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local taskData = self.RankPlayInfoList[index]
        grid:Refresh(taskData)
    end
end

function XUiDoubleTowersRank:Refresh()
    self:UpdateDynamicTable()
    self.MyGridRank:Refresh(self.RankData:GetMyRankPlayInfo())
end

--==============================
 ---@desc 排行榜倒计时
--==============================
function XUiDoubleTowersRank:RefreshCdTimer()
    self.TxtCurTime.text = XDataCenter.DoubleTowersManager.GetRankCountDownTime()
end 