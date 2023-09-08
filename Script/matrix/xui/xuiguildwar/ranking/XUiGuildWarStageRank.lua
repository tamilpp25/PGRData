--
local XUiGuildWarStageRank = XLuaUiManager.Register(XLuaUi, "UiGuildWarStageRank")

function XUiGuildWarStageRank:OnAwake()
    self:InitPanels()
    self.IsStay = false
end

function XUiGuildWarStageRank:InitPanels()
    self:InitTopControl()
    self:InitPanelAssets()
    self:InitRankingList()
    self:InitBtnToggle()
end

function XUiGuildWarStageRank:InitTopControl()
    self.TopController = XUiHelper.NewPanelTopControl(self, self.TopControlWhite)
    self:BindHelpBtn(self.BtnHelp, "GuildWarHelp")
end

function XUiGuildWarStageRank:InitPanelAssets()
    local actionId = XGuildWarConfig.GetServerConfigValue("ActivityPointItemId")
    local itemIds = {
        tonumber(actionId)
    }
    self.PanelAsset = XUiHelper.NewPanelActivityAssetSafe(itemIds, self.PanelAsset, self)
end

function XUiGuildWarStageRank:InitRankingList()
    local rankingList = require("XUi/XUiGuildWar/Ranking/XUiGuildWarStageRankList")
    self.RankingList = rankingList.New(self.PanelPlayerRankInfo)
end

function XUiGuildWarStageRank:InitBtnToggle()
    self.BtnToggle.CallBack = function() self:OnClickBtnToggle() end
end

function XUiGuildWarStageRank:OnClickBtnToggle()
    self.IsStay = not self.IsStay
    self.RankType = self.IsStay and XGuildWarConfig.RankingType.NodeStay or XGuildWarConfig.RankingType.Node
    self:RefreshBtnToggle()
end

function XUiGuildWarStageRank:RefreshBtnToggle()
    self:RefreshList()
end

function XUiGuildWarStageRank:OnStart(rankList, myRankInfo, rankType, uid, node)
    self.Uid = uid
    self.RankType = rankType
    if rankType == XGuildWarConfig.RankingType.Node then
        self.TxtStageName.text = XUiHelper.GetText("GuildWarNodeRankingTitle", node:GetName())
    elseif rankType == XGuildWarConfig.RankingType.NodeStay then
        self.TxtStageName.text = XUiHelper.GetText("GuildWarHomeRankingTitle")
    else
        self.TxtStageName.text = XUiHelper.GetText("GuildWarEliteNodeRankingTitle")
    end
    self.PanelStayToggle.gameObject:SetActiveEx(rankType == XGuildWarConfig.RankingType.Node
        or (rankType == XGuildWarConfig.RankingType.NodeStay))
    self.IsStay = rankType == XGuildWarConfig.RankingType.NodeStay
    self.BtnToggle:SetButtonState(self.IsStay and CS.UiButtonState.Select or CS.UiButtonState.Normal)
    self.RankingList:RefreshByData(rankList, myRankInfo, self.IsStay)
    self:StartAutoRefresh()
end

function XUiGuildWarStageRank:RefreshList()
    self.RankingList:RefreshList(self.RankType, self.Uid, self.IsStay)
end

function XUiGuildWarStageRank:StartAutoRefresh()
    if self.TimeId then return end
    self.TimeId = XScheduleManager.ScheduleForever(function()
                self:RefreshList()
            end, 5 * 60 * 1000
        )
end

function XUiGuildWarStageRank:StopAutoRefresh()
    if not self.TimeId then return end
    XScheduleManager.UnSchedule(self.TimeId)
    self.TimeId = nil
end

function XUiGuildWarStageRank:OnEnable()
    self:StartAutoRefresh()
end

function XUiGuildWarStageRank:OnDisable()
    self:StopAutoRefresh()
end

function XUiGuildWarStageRank:OnDestroy()
    self:StopAutoRefresh()
end