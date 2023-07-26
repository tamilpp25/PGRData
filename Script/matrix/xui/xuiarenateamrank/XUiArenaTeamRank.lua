local XUiArenaTeamRank = XLuaUiManager.Register(XLuaUi, "UiArenaTeamRank")

local XUiPanelTeamRank = require("XUi/XUiArenaTeamRank/XUiPanelTeamRank")
local XUiPanelRewardPreview = require("XUi/XUiArenaTeamRank/XUiPanelRewardPreview")
local XUiPanelArenaSelfRank = require("XUi/XUiArenaTeamRank/ArenaSelfRank/XUiPanelArenaSelfRank")

local ARENA_TEAM_RANK_PANEL_INDEX = {
    TEAM_RANK = 1,
    SELF_RANK = 2,
}

function XUiArenaTeamRank:OnAwake()
    self:AutoAddListener()
end

function XUiArenaTeamRank:OnStart()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)

    self.TeamRankPanel = XUiPanelTeamRank.New(self.PanelTeamRank, self)
    self.RewardPreviewPanel = XUiPanelRewardPreview.New(self.PanelRewardPreview, self)
    self.SelfRankPanel = XUiPanelArenaSelfRank.New(self.PanelSelfRank,self)
    self.PanelList = {}
    table.insert(self.PanelList, self.TeamRankPanel)
    table.insert(self.PanelList, self.SelfRankPanel)

    self.BtnList = {}
    table.insert(self.BtnList, self.BtnTeam)
    table.insert(self.BtnList, self.BtnPersonal)
    self.TypeButtonGroup:Init(self.BtnList,function(index) self:RefreshSelectedPanel(index) end,ARENA_TEAM_RANK_PANEL_INDEX.TEAM_RANK)
    self.TypeButtonGroup:SelectIndex(ARENA_TEAM_RANK_PANEL_INDEX.TEAM_RANK)
end

function XUiArenaTeamRank:AutoAddListener()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
end

function XUiArenaTeamRank:OnBtnBackClick()
    self:Close()
end

function XUiArenaTeamRank:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiArenaTeamRank:RefreshSelectedPanel(index)
    for i, panel in ipairs(self.PanelList) do
        if i == index then
            self:RefreshLevelTab(index,panel)
        else
            panel:Hide()
        end
        self.TeamRankPanel:Refresh(index)
    end
end

function XUiArenaTeamRank:RefreshLevelTab(index,panel)
    if not self.MyRankLevelButton then
        local obj = CS.UnityEngine.GameObject.Instantiate(self.GridRankLevel,self.PanelTags)
        ---@type XUiComponent.XUiButton
        self.MyRankLevelButton = obj:GetComponent("XUiButton")
    end
    local myChallengeId = XDataCenter.ArenaManager.GetCurChallengeId()
    local challengeCfg = XArenaConfigs.GetChallengeArenaCfgById(myChallengeId)
    local myLevelCfg = XArenaConfigs.GetArenaLevelCfgByLevel(challengeCfg.ArenaLv)
    self.MyRankLevelButton:SetNameByGroup(0, myLevelCfg.Name)
    self.MyRankLevelButton:SetNameByGroup(1, challengeCfg.MinLv .. "-" .. challengeCfg.MaxLv)
    self.MyRankLevelButton:SetRawImage(myLevelCfg.Icon)
    self.MyRankLevelButton:ShowTag(true)
    self.MyRankLevelButton.gameObject:SetActiveEx(true)
    if not self.MaxRankLevelButton then
        local obj = CS.UnityEngine.GameObject.Instantiate(self.GridRankLevel, self.PanelTags)
        ---@type XUiComponent.XUiButton
        self.MaxRankLevelButton = obj:GetComponent("XUiButton")
    end
    local maxChallengeCfg = XArenaConfigs.GetMaxChallengeCfg()
    local maxLevelCfg = XArenaConfigs.GetArenaLevelCfgByLevel(maxChallengeCfg.ArenaLv)
    self.MaxRankLevelButton:SetNameByGroup(0, maxLevelCfg.Name)
    self.MaxRankLevelButton:SetNameByGroup(1, maxChallengeCfg.MinLv .. "-" .. maxChallengeCfg.MaxLv)
    self.MaxRankLevelButton:SetRawImage(maxLevelCfg.Icon)
    self.MaxRankLevelButton.gameObject:SetActiveEx(not XArenaConfigs.IsMaxArenaLevel(challengeCfg.ArenaLv) and index == ARENA_TEAM_RANK_PANEL_INDEX.SELF_RANK)
    self.TagsButtonGroup:Init({ self.MyRankLevelButton, self.MaxRankLevelButton }, function(tagIndex)
        local challengeId = maxChallengeCfg.ChallengeId
        if tagIndex == 1 then
            challengeId = XDataCenter.ArenaManager.GetCurChallengeId()
        end
        panel:Show(challengeId)
    end)
    self.TagsButtonGroup:SelectIndex(1)
end 