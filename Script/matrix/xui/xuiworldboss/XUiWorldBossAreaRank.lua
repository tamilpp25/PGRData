local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
--工会boss关卡排行榜页面
local XUiGridWorldBossAreaRankItem = require("XUi/XUiWorldBoss/XUiGridWorldBossAreaRankItem")
local XUiWorldBossAreaRank = XLuaUiManager.Register(XLuaUi, "UiWorldBossAreaRank")

function XUiWorldBossAreaRank:OnAwake()
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end
    self:BindHelpBtn(self.BtnHelp, "")
    self.DynamicTable = XDynamicTableNormal.New(self.BossRankList)
    self.DynamicTable:SetProxy(XUiGridWorldBossAreaRankItem)
    self.DynamicTable:SetDelegate(self)
    self.GridAreaRank.gameObject:SetActiveEx(false)
end

function XUiWorldBossAreaRank:OnStart(areaId)
    self.AreaId = areaId
    XDataCenter.WorldBossManager.GetAttributeAreaRank(areaId, function() self:UpdateInfo() end)
end

function XUiWorldBossAreaRank:UpdateInfo()
    self.RankData = XDataCenter.WorldBossManager.GetOtherAreaRankData()
    self.MyRankData = XDataCenter.WorldBossManager.GetMyAreaRankData()
    self.DynamicTable:SetDataSource(self.RankData)
    self.DynamicTable:ReloadDataASync()
    self.PanelNoRank.gameObject:SetActiveEx(#self.RankData == 0)

    if next(self.MyRankData) then
        self.TxtScore.text = self.MyRankData.Score
        self.TxtName.text = XPlayer.Name

        local rankRate = math.ceil(self.MyRankData.Rank / self.MyRankData.ToTalRank * 100)
        if rankRate >= 100 then
            rankRate = 99
        end
        self.TxtRank.text = self.MyRankData.Rank <= 100 and self.MyRankData.Rank or string.format("%d%s", rankRate, "%")

        XUiPlayerHead.InitPortrait(XPlayer.CurrHeadPortraitId, XPlayer.CurrHeadFrameId, self.UObjHead)
    end
    self.PanelMyAreaRank.gameObject:SetActiveEx(next(self.MyRankData))
end

function XUiWorldBossAreaRank:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Init(self.RankData[index])
    end
end

function XUiWorldBossAreaRank:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiWorldBossAreaRank:OnDestroy()

end

function XUiWorldBossAreaRank:OnBtnBackClick()
    self:Close()
end
