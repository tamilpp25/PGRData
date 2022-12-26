local XUiChessPursuitRankGrid = require("XUi/XUiChessPursuit/XUi/Rank/XUiChessPursuitRankGrid")
local XUiChessPursuitMyRankGrid = require("XUi/XUiChessPursuit/XUi/Rank/XUiChessPursuitMyRankGrid")
local XUiPanelRankReward = require("XUi/XUiChessPursuit/XUi/Rank/XUiChessPursuitPanelRankReward")

local XUiChessPursuitRank = XLuaUiManager.Register(XLuaUi, "UiChessPursuitRank")

function XUiChessPursuitRank:OnAwake()
    self.PanelRankReward.gameObject:SetActiveEx(false)
    self.PlayerRank.gameObject:SetActiveEx(false)
    self.RankReward = XUiPanelRankReward.New(self, self.PanelRankReward)

    self.MyRankGrid = XUiChessPursuitMyRankGrid.New(self.PanelMyRank, self)
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self:AutoAddListener()
    self:InitDynamicTable()
end

function XUiChessPursuitRank:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PlayerRankList)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(XUiChessPursuitRankGrid, self)
end

function XUiChessPursuitRank:AutoAddListener()
    self:RegisterClickEvent(self.BtnBack, self.Close)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:RegisterClickEvent(self.BtnRankReward, self.OnBtnRankRewardClick)
    self:BindHelpBtn(self.BtnHelp, "ChessPursuit")
end

function XUiChessPursuitRank:OnStart(groupId)
    self.GroupId = groupId
end

function XUiChessPursuitRank:OnEnable()
    self:Refresh()
    self:SetRefreshTimer()
end

function XUiChessPursuitRank:OnDisable()
    self:RemoveTimer()
end

function XUiChessPursuitRank:Refresh()
    self:RefreshDynamicTable()
    self:RefreshMyRank()
end

function XUiChessPursuitRank:RefreshMyRank()
    self.MyRankGrid:Refresh()
end

function XUiChessPursuitRank:RefreshDynamicTable()
    self.RankDataList = XDataCenter.ChessPursuitManager.GetRankDataList()
    if XTool.IsTableEmpty(self.RankDataList) then
        self.PlayerRankList.gameObject:SetActiveEx(false)
        self.PanelNoRank.gameObject:SetActiveEx(true)
    else
        self.PanelNoRank.gameObject:SetActiveEx(false)
        self.DynamicTable:SetDataSource(self.RankDataList)
        self.DynamicTable:ReloadDataASync()
        self.PlayerRankList.gameObject:SetActiveEx(true)
    end
end

function XUiChessPursuitRank:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local rankDataTemplate = self.RankDataList[index]
        grid:Refresh(rankDataTemplate, index, self.GroupId)
    end
end

function XUiChessPursuitRank:OnBtnRankRewardClick()
    self.RankReward:ShowPanel()
end

function XUiChessPursuitRank:SetRefreshTimer()
    self:RemoveTimer()
    self.Timer = XScheduleManager.ScheduleForever(function()
        self:CheckIsClose()
    end, 1000)
end

function XUiChessPursuitRank:RemoveTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiChessPursuitRank:CheckIsClose()
    local isOpen = XChessPursuitConfig.IsChessPursuitMapGroupOpen(self.GroupId)
    if not isOpen then
        XUiManager.TipText("ActivityAlreadyOver")
        self:RemoveTimer()
        XLuaUiManager.Close("UiChessPursuitRankLineup")
        self:Close()
    end
end

function XUiChessPursuitRank:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end