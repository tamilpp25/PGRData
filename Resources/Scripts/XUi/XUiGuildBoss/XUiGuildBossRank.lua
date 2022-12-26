--工会boss关卡排行榜页面
local XUiGuildBossRankItem = require("XUi/XUiGuildBoss/Component/XUiGuildBossRankItem")
local XUiGuildBossRank = XLuaUiManager.Register(XLuaUi, "UiGuildBossRank")

function XUiGuildBossRank:OnAwake()
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end
    self:BindHelpBtn(self.BtnHelp, "GuildBossHelp")
    self.DynamicTable = XDynamicTableNormal.New(self.BossRankList)
    self.DynamicTable:SetProxy(XUiGuildBossRankItem)
    self.DynamicTable:SetDelegate(self)
    self.GridBossRank.gameObject:SetActiveEx(false)
end

function XUiGuildBossRank:OnStart(stageId)
    self.StageId = stageId
    XDataCenter.GuildBossManager.GuildBossPlayerStageRankRequest(stageId, function() self:UpdateInfo() end)
end

function XUiGuildBossRank:UpdateInfo()
    self.RankData = XDataCenter.GuildBossManager.GetDetailLevelRankData(self.StageId)
    self.DynamicTable:SetDataSource(self.RankData)
    self.DynamicTable:ReloadDataASync()
    self.PanelNoRank.gameObject:SetActiveEx(#self.RankData == 0)

    --我自己
    self.MyData = nil
    for i = 1, #self.RankData do
        if self.RankData[i].Id == XPlayer.Id then
            self.MyData = self.RankData[i]
            self.MyData.Rank = i
        end
    end
    if self.MyData ~= nil then
        self.TxtRank.text = self.MyData.Rank
        self.TxtScore.text = self.MyData.Score
        self.TxtName.text = self.MyData.Name
        self.TxtRankName.text = XDataCenter.GuildManager.GetRankNameByLevel(self.MyData.RankLevel)
        XUiPLayerHead.InitPortrait(self.MyData.HeadPortraitId, self.MyData.HeadFrameId, self.UObjHead)
    end
    self.PanelMyBossRank.gameObject:SetActiveEx(self.MyData ~= nil)
end

function XUiGuildBossRank:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Init(self.RankData[index], index)
    end
end

function XUiGuildBossRank:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiGuildBossRank:OnBtnBackClick()
    self:Close()
end
