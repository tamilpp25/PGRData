local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiFubenMaverickRank = XLuaUiManager.Register(XLuaUi, "UiFubenMaverickRank")
local XUiFubenMaverickRankGrid = require("XUi/XUiFubenMaverick/XUiGrid/XUiFubenMaverickRankGrid")

function XUiFubenMaverickRank:OnAwake()
    self:InitTexts()
    self:InitButtons()
    self:InitRankEntity()
    self:InitPanelAssets()
end

function XUiFubenMaverickRank:OnStart()
    --Start时初始化界面为空
    self:Refresh()

    self:SetAutoCloseInfo(XDataCenter.MaverickManager.GetEndTime(), function(isClose)
        if isClose then
            XDataCenter.MaverickManager.EndActivity()
        end
    end, nil , 0)
end

function XUiFubenMaverickRank:OnEnable()
    self.Super.OnEnable(self)

    XDataCenter.MaverickManager.GetRankData(function(data)
        self.MyRankData = data.MyRankData
        self.RankListData = data.RankListData
        self.MaxRankCount = data.MaxRankCount
        self:Refresh()
    end)
end

function XUiFubenMaverickRank:Refresh()
    self.MyGridRank:Refresh(self.MyRankData)

    self.DynamicTable:SetDataSource(self.RankListData)
    self.DynamicTable:ReloadDataSync()

    self.PanelNoRank.gameObject:SetActiveEx(XTool.IsTableEmpty(self.RankListData))
end

function XUiFubenMaverickRank:InitRankEntity()
    self.MyGridRank = XUiFubenMaverickRankGrid.New(self.GridMyRank)
    self.MyGridRank.IsMyself = true
    self.MyGridRank.RootUi = self
    
    self.DynamicTable = XDynamicTableNormal.New(self.RankList)
    self.DynamicTable:SetProxy(XUiFubenMaverickRankGrid)
    self.DynamicTable:SetDelegate(self)
    self.GridRank.gameObject:SetActiveEx(false)
end

function XUiFubenMaverickRank:InitButtons()
    self:BindHelpBtn(self.BtnHelp, "MaverickHelp")
    self.BtnBack.CallBack = function() self:Close() end
    self.BtnMainUi.CallBack = function() XLuaUiManager.RunMain() end
end

function XUiFubenMaverickRank:InitTexts()
    self.TxtTisp.text = CSXTextManagerGetText("MaverickRankTip")
    self.TxtRankCount.text = "TOP" .. XDataCenter.MaverickManager.RankTopCount
end

function XUiFubenMaverickRank:InitPanelAssets()
    XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem,
            XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
end

function XUiFubenMaverickRank:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid.RootUi = self
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.RankListData[index])
    end
end