local XUiPanelInfestorExploreBossRank = require("XUi/XUiFubenInfestorExplore/XUiPanelInfestorExploreBossRank")
local XUiGridInfestorExploreRank = require("XUi/XUiFubenInfestorExplore/XUiGridInfestorExploreRank")

local CSXTextManagerGetText = CS.XTextManager.GetText

local XUiInfestorExploreRank = XLuaUiManager.Register(XLuaUi, "UiInfestorExploreRank")

function XUiInfestorExploreRank:OnAwake()
    self:AutoAddListener()
    self.GridArenaTeamRank.gameObject:SetActiveEx(false)
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.BossRank = XUiPanelInfestorExploreBossRank.New(self.PanelRank2)
    self.BtnShop.gameObject:SetActiveEx(false)
    self.BtnChat.gameObject:SetActiveEx(false)
end

function XUiInfestorExploreRank:OnStart()
    self:InitView()
    self:InitDynamicTable()
end

function XUiInfestorExploreRank:OnEnable()
    self:RefreshView()

    XDataCenter.FubenInfestorExploreManager.CheckNewDiff()
end

function XUiInfestorExploreRank:OnDisable()
    XCountDown.UnBindTimer(self, XCountDown.GTimerName.FubenInfestorExplore)
end

function XUiInfestorExploreRank:OnGetEvents()
    return { XEventId.EVENT_INFESTOREXPLORE_REFRESH_PALYER_RANK }
end

function XUiInfestorExploreRank:OnNotify(evt, ...)
    local args = { ... }
    if evt == XEventId.EVENT_INFESTOREXPLORE_REFRESH_PALYER_RANK then
        self:UpdateRank()
    end
end

function XUiInfestorExploreRank:InitView()
    self.TxtTitle.text = CSXTextManagerGetText("InfestorExploreName")
end

function XUiInfestorExploreRank:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.SViewRank)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(XUiGridInfestorExploreRank)
end

function XUiInfestorExploreRank:RefreshView()
    self:UpdateSectionInfo()
    self:UpdateLevel()
    self:UpdateRank()
end

function XUiInfestorExploreRank:UpdateSectionInfo()
    self.TxtSection.text = XDataCenter.FubenInfestorExploreManager.GetCurSectionName()
    XCountDown.BindTimer(self, XCountDown.GTimerName.FubenInfestorExplore, function(time)
        time = time > 0 and time or 0
        local timeText = XUiHelper.GetTime(time, XUiHelper.TimeFormatType.CHALLENGE)
        self.TxtTime.text = CSXTextManagerGetText("InfestorExploreSectionLeftTime", timeText)
    end)
end

function XUiInfestorExploreRank:UpdateLevel()
    self.TxtArenaName.text = XDataCenter.FubenInfestorExploreManager.GetDiffName()

    local icon = XDataCenter.FubenInfestorExploreManager.GetDiffIcon()
    self.RImgArenaLevel:SetRawImage(icon)

    local minLevel, maxLevel = XDataCenter.FubenInfestorExploreManager.GetCurGroupLevelBorder()
    self.TxtLevelRegion.text = CSXTextManagerGetText("InfestorExploreDiffLevelBorder", minLevel, maxLevel)
end

function XUiInfestorExploreRank:UpdateRank()
    if XDataCenter.FubenInfestorExploreManager.IsInSectionOne() then
        self:UpdateRank1()
    elseif XDataCenter.FubenInfestorExploreManager.IsInSectionTwo() then
        self:UpdateRank2()
    end
end

function XUiInfestorExploreRank:UpdateRank1()
    self.RankIndexList = XDataCenter.FubenInfestorExploreManager.GetPlayerRankIndexList()
    self.DynamicTable:SetDataSource(self.RankIndexList)
    self.DynamicTable:ReloadDataSync()

    self.PanelRank1.gameObject:SetActiveEx(true)
    self.BossRank.GameObject:SetActiveEx(false)
end

function XUiInfestorExploreRank:UpdateRank2()
    self.BossRank:Refresh()
    self.PanelRank1.gameObject:SetActiveEx(false)
    self.BossRank.GameObject:SetActiveEx(true)
end

function XUiInfestorExploreRank:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local rankIndex = self.RankIndexList[index]
        grid:Refresh(rankIndex)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local rankIndex = self.RankIndexList[index]
        local playerId = XDataCenter.FubenInfestorExploreManager.GetRankPlayerId(rankIndex)
        if playerId and playerId ~= XPlayer.Id then
            XDataCenter.PersonalInfoManager.ReqShowInfoPanel(playerId)
        end
    end
end

function XUiInfestorExploreRank:AutoAddListener()
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end
    self:BindHelpBtn(self.BtnHelp, "InfestorExplore")
    self.BtnDetails.CallBack = function() self:OnClickBtnDetails() end
    self.BtnFight.CallBack = function() self:OnClickBtnFight() end
    self.BtnChat.CallBack = function() self:OnClickBtnChat() end
    self.BtnShop.CallBack = function() self:OnClickBtnShop() end
end

function XUiInfestorExploreRank:OnBtnBackClick()
    self:Close()
end

function XUiInfestorExploreRank:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiInfestorExploreRank:OnClickBtnDetails()
    self:OpenChildUi("UiInfestorExploreLevelDetail")
    self:FindChildUiObj("UiInfestorExploreLevelDetail"):UpdateView()
end

function XUiInfestorExploreRank:OnClickBtnFight()
    if XDataCenter.FubenInfestorExploreManager.IsInSectionOne() then
        XLuaUiManager.Open("UiInfestorExploreChapter")
    elseif XDataCenter.FubenInfestorExploreManager.IsInSectionTwo() then
        XLuaUiManager.Open("UiInfestorExploreChapterPart2")
    end
end

function XUiInfestorExploreRank:OnClickBtnChat()

end

function XUiInfestorExploreRank:OnClickBtnShop()

end