local XUiArenaActivityResult = XLuaUiManager.Register(XLuaUi, "UiArenaActivityResult")

function XUiArenaActivityResult:OnAwake()
    self:AutoAddListener()
end

function XUiArenaActivityResult:OnStart(data, callBack, closeCb)
    self.GridCommon.gameObject:SetActive(false)

    self.DynamicTable = XDynamicTableNormal.New(self.SViewReward.transform)
    self.DynamicTable:SetProxy(XUiGridCommon)
    self.DynamicTable:SetDelegate(self)

    self.Data = data
    self.CallBack = callBack
    self.CloseCb = closeCb

    self:Refresh()
end

function XUiArenaActivityResult:AutoAddListener()
    self:RegisterClickEvent(self.BtnBg, self.OnBtnBgClick)
    self:RegisterClickEvent(self.BtnRanking, self.OnBtnRankingClick)
end

function XUiArenaActivityResult:OnBtnBgClick()
    self:Close()
    if self.CloseCb then
        self.CloseCb()
    end
end

function XUiArenaActivityResult:OnBtnRankingClick()
    XDataCenter.ArenaManager.ScoreQueryReq(function()
        self:Close()
        XLuaUiManager.Open("UiArenaRank")
    end)
end

function XUiArenaActivityResult:Refresh()
    if not self.Data then
        return
    end

    local arenaLevelCfg = XArenaConfigs.GetArenaLevelCfgByLevel(self.Data.NewArenaLevel)
    local str

    --降级保护
    if self.Data.IsProtected then
        str = CS.XTextManager.GetText("ArenaActivityProtected", arenaLevelCfg.Name)
    else
        if self.Data.OldArenaLevel < self.Data.NewArenaLevel then
            str = CS.XTextManager.GetText("ArenaActivityResultUp", arenaLevelCfg.Name)
        elseif self.Data.OldArenaLevel == self.Data.NewArenaLevel then
            str = CS.XTextManager.GetText("ArenaActivityResultKeep", arenaLevelCfg.Name)
            -- 英雄小队
            local challengeCfg = XArenaConfigs.GetChallengeArenaCfgById(self.Data.ChallengeId)
            if challengeCfg.ArenaLv == XArenaConfigs.ArenaHeroLv and challengeCfg.DanUpRankCostContributeScore > 0 and self.Data.GroupRank <= challengeCfg.DanUpRank then
                str = XUiHelper.GetText("ArenaActivityResultNotContributeScore", challengeCfg.DanUpRankCostContributeScore, arenaLevelCfg.Name)
            end
        else
            str = CS.XTextManager.GetText("ArenaActivityResultDown", arenaLevelCfg.Name)
        end
    end
    self.RewardGoodsList = self:RewardGoodsList()

    self.TxtInfo.text = str
    self.RImgArenaLevel:SetRawImage(arenaLevelCfg.Icon)
    self.DynamicTable:SetDataSource(self.RewardGoodsList)
    self.DynamicTable:ReloadDataASync()

    if self.CallBack then
        self.CallBack()
    end
end

function XUiArenaActivityResult:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.RewardGoodsList[index]
        grid.RootUi = self
        grid:Refresh(data)
    end
end

function XUiArenaActivityResult:RewardGoodsList()
    local list = {}
    for i,v in ipairs(self.Data.RewardGoodsList) do
        table.insert(list, v)
    end

    local challengeCfg = XArenaConfigs.GetChallengeArenaCfgById(self.Data.ChallengeId)
    local point = self.Data.Point or 0
    local contributeScore = XDataCenter.ArenaManager.GetContributeScoreByCfg(self.Data.GroupRank, challengeCfg, point)

    --显示战区贡献积分
    if contributeScore then
        table.insert(list, {
            TemplateId = XArenaConfigs.CONTRIBUTESCORE_ID,
            Count = contributeScore,
        })
    end

    return list
end