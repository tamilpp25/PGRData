local XUiGridAreaWarRank = require("XUi/XUiAreaWar/XUiGridAreaWarRank")

local XUiAreaWarRankingList = XLuaUiManager.Register(XLuaUi, "UiAreaWarRankingList")

function XUiAreaWarRankingList:OnAwake()
    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool)
    XDataCenter.ItemManager.AddCountUpdateListener(
        {
            XDataCenter.ItemManager.ItemId.AreaWarCoin,
            XDataCenter.ItemManager.ItemId.AreaWarActionPoint
        },
        handler(self, self.UpdateAssets),
        self.AssetActivityPanel
    )

    self.PanelMyRank.gameObject:SetActiveEx(false)
    self.PlayerRank.gameObject:SetActiveEx(false)

    self.DynamicTable = XDynamicTableNormal.New(self.PlayerRankList)
    self.DynamicTable:SetProxy(XUiGridAreaWarRank)
    self.DynamicTable:SetDelegate(self)

    self:AutoAddListener()
end

function XUiAreaWarRankingList:OnStart(blockId)
    self.BlockId = blockId
    
    self.TxtTitle.text = XAreaWarConfigs.GetBlockWorldBossRankTitle(blockId)
end

function XUiAreaWarRankingList:OnEnable()
    self:UpdateAssets()
    self:UpdateRank()
end

function XUiAreaWarRankingList:AutoAddListener()
    self:BindHelpBtn(self.BtnHelp, "AreaWarRankingList")
    self.BtnBack.CallBack = function()
        self:Close()
    end
    self.BtnMainUi.CallBack = function()
        XLuaUiManager.RunMain()
    end
end

function XUiAreaWarRankingList:UpdateAssets()
    self.AssetActivityPanel:Refresh(
        {
            XDataCenter.ItemManager.ItemId.AreaWarCoin,
            XDataCenter.ItemManager.ItemId.AreaWarActionPoint
        },
        {
            XDataCenter.ItemManager.ItemId.AreaWarActionPoint
        }
    )
end

function XUiAreaWarRankingList:UpdateRank()
    local blockId = self.BlockId

    local myRankItem = XDataCenter.AreaWarManager.GetWorldBossBlockRankMyRankItem(blockId)
    self.PanelMyRankItem = self.PanelMyRankItem or XUiGridAreaWarRank.New(self.PanelMyRank)
    self.PanelMyRankItem:Refresh(myRankItem)
    self.PanelMyRankItem.GameObject:SetActiveEx(true)

    self.RankList = XDataCenter.AreaWarManager.GetWorldBossBlockRankList(blockId)
    self.PanelNoRank.gameObject:SetActiveEx(XTool.IsTableEmpty(self.RankList))
    self.DynamicTable:SetDataSource(self.RankList)
    self.DynamicTable:ReloadDataSync()
end

function XUiAreaWarRankingList:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.RankList[index])
    end
end
