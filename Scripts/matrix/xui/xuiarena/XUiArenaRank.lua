local XUiArenaRank = XLuaUiManager.Register(XLuaUi, "UiArenaRank")
local XUiArenaRankGrid = require("XUi/XUiArena/XUiArenaRankGrid")
local XUiArenaContributeScore = require("XUi/XUiArena/XUiArenaContributeScore")

function XUiArenaRank:OnAwake()
    self:AutoAddListener()
end

function XUiArenaRank:OnStart()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)

    self.TeamMemberList = {}
    table.insert(self.TeamMemberList, self.GridMember1)
    table.insert(self.TeamMemberList, self.GridMember2)

    self.GridTitleCache = {}
    table.insert(self.GridTitleCache, self.GridTitle)
    self.GridPlayerCache = {}

    self.GridMember1.transform.parent.gameObject:SetActiveEx(false)
    self.GridPlayer.gameObject:SetActiveEx(false)
    self:Refresh()
end

function XUiArenaRank:AutoAddListener()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:RegisterClickEvent(self.BtnTeamRank, self.OnBtnTeamRankClick)
    self:RegisterClickEvent(self.BtnArenaLevelDetail, self.OnBtnArenaLevelDetailClick)
    self:RegisterClickEvent(self.BtnDetailsA, self.OnBtnBtnDetailsClick)
    self:RegisterClickEvent(self.BtnDetailsB, self.OnBtnBtnDetailsClick)
    self:RegisterClickEvent(self.BtnTxtNumber, self.OnBtnTxtNumber)
end

function XUiArenaRank:OnBtnBtnDetailsClick()
    XLuaUiManager.Open("UiArenaContributeTips", false)
end

function XUiArenaRank:OnBtnTxtNumber()
    XLuaUiManager.Open("UiArenaContributeTips", false, 2)
end

function XUiArenaRank:OnBtnBackClick()
    self:Close()
end

function XUiArenaRank:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiArenaRank:OnBtnArenaLevelDetailClick()
    XLuaUiManager.Open("UiArenaLevelDetail")
end

function XUiArenaRank:OnBtnTeamRankClick()
    XDataCenter.ArenaManager.RequestTeamRankData(function()
        XLuaUiManager.Open("UiArenaTeamRank")
    end)
end

function XUiArenaRank:Refresh()
    local challengeCfg = XDataCenter.ArenaManager.GetLastChallengeCfg()
    if challengeCfg then
        self.TxtLevelRange.text = CS.XTextManager.GetText("ArenaPlayerLevelRange", challengeCfg.MinLv, challengeCfg.MaxLv)
        self.TxtArenaRegion.text = challengeCfg.Name
    end

    local arenaLevel = XDataCenter.ArenaManager.GetLastArenaLevel()
    local arenaLevelCfg = XArenaConfigs.GetArenaLevelCfgByLevel(arenaLevel)
    if arenaLevelCfg then
        self.RImgArenaLevel:SetRawImage(arenaLevelCfg.Icon)
    end

    self.TxtRankDesc.gameObject:SetActiveEx(false)
    self:RefreshSelfInfo()
    self:RefreshTeamInfo()
    self:RefreshArenaPlayerRank()
end

-- 自身
function XUiArenaRank:RefreshSelfInfo()
    local wave = XDataCenter.ArenaManager.GetWaveLastRate()
    local rank, region = XDataCenter.ArenaManager.GetLastPlayerArenaRankAndRegion()
    local selfInfo = XDataCenter.ArenaManager.GetPlayerLastArenaInfo()
    local challengeCfg = XDataCenter.ArenaManager.GetLastChallengeCfg()
    local contributeScore = XDataCenter.ArenaManager.GetContributeScoreByCfg(rank, challengeCfg, selfInfo.Point)
    local maxContributeScore = XDataCenter.ArenaManager.GetLastContributeScore()

    self.TxtWave.text = CS.XTextManager.GetText("ArenaWaveRate", wave)
    self.TxtSelfNickname.text = selfInfo.Name
    self.TxtPoint.text = selfInfo.Point
    self.TxtRank.text = "No." .. rank

    if self.PanelPromotion then
        self.PanelPromotion.gameObject:SetActiveEx(false)
    end
    self.TxtRankRange.gameObject:SetActiveEx(true)
    -- 英雄小队
    if challengeCfg.ArenaLv == XArenaConfigs.ArenaHeroLv and challengeCfg.DanUpRankCostContributeScore > 0 and
            region == XArenaPlayerRankRegion.UpRegion and
            maxContributeScore >= challengeCfg.DanUpRankCostContributeScore then
        if self.PanelPromotion then
            self.PanelPromotion.gameObject:SetActiveEx(true)
        end
        self.TxtRankRange.gameObject:SetActiveEx(false)
    else
        self.TxtRankRange.text = XArenaConfigs.GetRankRegionText(region)
    end
    XUiPLayerHead.InitPortrait(selfInfo.CurrHeadPortraitId, selfInfo.CurrHeadFrameId, self.Head)
    
    if maxContributeScore >= CS.XGame.Config:GetInt("ArenaProtectContributeScore") then
        self.PanelContribute.gameObject:SetActiveEx(false)
        self.PanelContributeActivation.gameObject:SetActiveEx(true)
    else        
        self.TxtSumNumber.text = maxContributeScore
        self.ImgJd.fillAmount = maxContributeScore / CS.XGame.Config:GetInt("ArenaMaxContributeScore")

        self.PanelContribute.gameObject:SetActiveEx(true)
        self.PanelContributeActivation.gameObject:SetActiveEx(false)
    end
    XUiArenaContributeScore.Refresh(self.TxtNumber, contributeScore, selfInfo.Point, "000000FF")
end

-- 队伍
function XUiArenaRank:RefreshTeamInfo()
    self.TxtTeamPoint.text = XDataCenter.ArenaManager.GetLastArenaTeamTotalPoint()
    local teamMemberList = XDataCenter.ArenaManager.GetPlayerLastArenaTeamMemberInfo()
    for i, grid in ipairs(self.TeamMemberList) do
        local head = XUiHelper.TryGetComponent(grid.transform, "Head")
        local nickname = XUiHelper.TryGetComponent(grid.transform, "TxtNickname", "Text")
        local btnHead = XUiHelper.TryGetComponent(grid.transform, "BtnHead", "Button")

        CsXUiHelper.RegisterClickEvent(btnHead, function()
            local memberInfo = teamMemberList[i]
            if memberInfo then
                XDataCenter.PersonalInfoManager.ReqShowInfoPanel(memberInfo.Id)
            end
        end, true)

        local member = teamMemberList[i]
        if member then
            nickname.text = XDataCenter.SocialManager.GetPlayerRemark(member.Id, member.Name)
            XUiPLayerHead.InitPortrait(member.CurrHeadPortraitId, member.CurrHeadFrameId, head)
        else
            nickname.text = ""
            XUiPLayerHead.Hide(head)
        end
    end
end

function XUiArenaRank:RefreshArenaPlayerRank()
    local challengeCfg = XDataCenter.ArenaManager.GetLastChallengeCfg()
    local rankData = XDataCenter.ArenaManager.GetLastPlayerArenaRankList()

    for _, v in ipairs(self.GridTitleCache) do
        v.gameObject:SetActiveEx(false)
    end
    for _, v in ipairs(self.GridPlayerCache) do
        v.GameObject:SetActiveEx(false)
    end

    if not challengeCfg then
        return
    end

    self.SiblingIndex = 1
    local titleIndex = 1
    -- 是否是英雄小队
    local isHeroTeam = challengeCfg.ArenaLv == XArenaConfigs.ArenaHeroLv and challengeCfg.DanUpRankCostContributeScore > 0
    
    -- 晋级区
    if challengeCfg.DanUpRank > 0 then
        self:AddTitle(titleIndex, challengeCfg.UpRewardId)
        for _, info in ipairs(rankData.UpList) do
            local isShow = true
            if isHeroTeam then
                isShow = self:CheckShowPlayer(challengeCfg, info, titleIndex)
            end
            if isShow then
                self:AddPlayer(info)
            end
        end
    end

    -- 保级区
    titleIndex = titleIndex + 1
    self:AddTitle(titleIndex, challengeCfg.KeepRewardId)
    if isHeroTeam then
        for _, info in ipairs(rankData.UpList) do
            if self:CheckShowPlayer(challengeCfg, info, titleIndex) then
                self:AddPlayer(info)
            end
        end
    end
    for _, info in ipairs(rankData.KeepList) do
        self:AddPlayer(info)
    end

    -- 降级区
    if challengeCfg.DanDownRank > 0 then
        titleIndex = titleIndex + 1
        self:AddTitle(titleIndex, challengeCfg.DownRewardId)
        for _, info in ipairs(rankData.DownList) do
            self:AddPlayer(info)
        end
    end
end

function XUiArenaRank:AddTitle(rankRegion, rewardId)
    local grid = self.GridTitleCache[rankRegion]
    if not grid then
        local go = CS.UnityEngine.GameObject.Instantiate(self.GridTitle.gameObject)
        grid = go.transform
        grid:SetParent(self.PanelContent, false)
        table.insert(self.GridTitleCache, grid)
    end
    grid.gameObject:SetActiveEx(true)

    grid:SetSiblingIndex(self.SiblingIndex - 1)
    self.SiblingIndex = self.SiblingIndex + 1

    -- 界面显示
    local rankRange = XUiHelper.TryGetComponent(grid.transform, "TxtRankRange", "Text")
    local rewardIcon = XUiHelper.TryGetComponent(grid.transform, "ImgReward", "Image")
    local rewardCount = XUiHelper.TryGetComponent(grid.transform, "ImgRewardCount", "Text")
    local btnTitle = XUiHelper.TryGetComponent(grid.transform, "BtnTitle", "Button")
    local btnReward = XUiHelper.TryGetComponent(grid.transform, "ImgReward/BtnReward", "Button")

    CsXUiHelper.RegisterClickEvent(btnTitle, function()
        XLuaUiManager.Open("UiArenaLevelDetail")
    end, true)

    CsXUiHelper.RegisterClickEvent(btnReward, function()
        local list = XRewardManager.GetRewardList(rewardId)
        if not list or #list <= 0 then
            return
        end
        local goodsShowParams = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(list[1].TemplateId)
        if goodsShowParams.RewardType == XRewardManager.XRewardType.Character then
            XLuaUiManager.Open("UiCharacterDetail", list[1].TemplateId)
        elseif goodsShowParams.RewardType == XRewardManager.XRewardType.Equip then
            XMVCA:GetAgency(ModuleId.XEquip):OpenUiEquipPreview(list[1].TemplateId)
        else
            XLuaUiManager.Open("UiTip", list[1] and list[1] or list[1].TemplateId)
        end
    end, true)

    rankRange.text = XArenaConfigs.GetRankRegionText(rankRegion)
    local rewards = XRewardManager.GetRewardList(rewardId)
    if not rewards or #rewards <= 0 then
        return
    end
    local iconPath = XGoodsCommonManager.GetGoodsIcon(rewards[1].TemplateId)
    self:SetUiSprite(rewardIcon, iconPath)
    rewardCount.text = rewards[1].Count
end

function XUiArenaRank:AddPlayer(data)
    local xUiArenaRankGrid = self.GridPlayerCache[data.Rank]
    if not xUiArenaRankGrid then
        local grid = CS.UnityEngine.GameObject.Instantiate(self.GridPlayer.gameObject)
        grid.transform:SetParent(self.PanelContent, false)
        xUiArenaRankGrid = XUiArenaRankGrid.New(grid)
        table.insert(self.GridPlayerCache, xUiArenaRankGrid)
    end

    xUiArenaRankGrid:Refresh(data)
    xUiArenaRankGrid:SetSiblingIndex(self.SiblingIndex - 1)
    self.SiblingIndex = self.SiblingIndex + 1
end

function XUiArenaRank:CheckShowPlayer(challengeCfg, data, rankRegion)
    local playerInfo = data.PlayerInfo
    local contributeScore = playerInfo.ContributeScore or 0
    if rankRegion == XArenaPlayerRankRegion.UpRegion then
        if contributeScore >= challengeCfg.DanUpRankCostContributeScore then
            return true
        end
    end

    if rankRegion == XArenaPlayerRankRegion.KeepRegion then
        if contributeScore < challengeCfg.DanUpRankCostContributeScore then
            return true
        end
    end
    
    return false
end

return XUiArenaRank