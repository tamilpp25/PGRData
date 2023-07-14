local XUiPanelActive = XClass(nil, "XUiPanelActive")
local XUiArenaGrid = require("XUi/XUiArena/XUiArenaGrid")
local XUiArenaContributeScore = require("XUi/XUiArena/XUiArenaContributeScore")

function XUiPanelActive:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self:AutoAddListener()
    self:RegisterRedPointEvent()

    self.TeamMemberList = {}
    table.insert(self.TeamMemberList, self.GridMember1)
    table.insert(self.TeamMemberList, self.GridMember2)

    self.GridTitleCache = {}
    table.insert(self.GridTitleCache, self.GridTitle)
    self.GridPlayerCache = {}

    self.GridPlayer.gameObject:SetActive(false)
    self.IsShow = false
    self.GameObject:SetActive(false)
end

function XUiPanelActive:CheckRedPoint()
    if self.EventId then
        XRedPointManager.Check(self.EventId)
    end
end

function XUiPanelActive:RegisterRedPointEvent()
    self.EventId = XRedPointManager.AddRedPointEvent(self.ImgRedLegion, self.OnCheckTaskNews, self, { XRedPointConditions.Types.CONDITION_ARENA_MAIN_TASK })
end

--@region 注册点击事件

function XUiPanelActive:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiPanelActive:RegisterClickEvent函数参数错误：参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiPanelActive:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiPanelActive:AutoAddListener()
    self:RegisterClickEvent(self.BtnDetail, self.OnBtnDetailClick)
    self:RegisterClickEvent(self.BtnTeamRank, self.OnBtnTeamRankClick)
    self:RegisterClickEvent(self.BtnSelectWarZone, self.OnBtnSelectWarZoneClick)
    self:RegisterClickEvent(self.BtnArenaTask, self.OnBtnArenaTaskClick)
    self:RegisterClickEvent(self.BtnArenaLevelDetail, self.OnBtnArenaLevelDetailClick)
    self:RegisterClickEvent(self.BtnShop, self.OnBtnShopClick)
    self:RegisterClickEvent(self.BtnDetailsA, self.OnBtnBtnDetailsClick)
    self:RegisterClickEvent(self.BtnDetailsB, self.OnBtnBtnDetailsClick)
    self:RegisterClickEvent(self.BtnTxtNumber, self.OnBtnTxtNumber)
end

function XUiPanelActive:OnBtnArenaLevelDetailClick()
    XLuaUiManager.Open("UiArenaLevelDetail")
end

function XUiPanelActive:OnBtnDetailClick()
    XUiManager.UiFubenDialogTip("", CS.XTextManager.GetText("ArenaActivityStrategyContent") or "")
end

function XUiPanelActive:OnBtnTeamRankClick()
    XDataCenter.ArenaManager.RequestTeamRankData(function()
        XLuaUiManager.Open("UiArenaTeamRank")
    end)
end

function XUiPanelActive:OnBtnSelectWarZoneClick()
    XLuaUiManager.Open("UiArenaWarZone")
end

function XUiPanelActive:OnBtnArenaTaskClick()
    XLuaUiManager.Open("UiArenaTask")
end

function XUiPanelActive:OnBtnShopClick()
    XLuaUiManager.Open("UiShop", XShopManager.ShopType.Arena)
end

function XUiPanelActive:OnBtnBtnDetailsClick()
    XLuaUiManager.Open("UiArenaContributeTips", true)
end

function XUiPanelActive:OnBtnTxtNumber()
    XLuaUiManager.Open("UiArenaContributeTips", true, 2)
end

--@endregion

function XUiPanelActive:Show()
    if self.IsShow then
        XDataCenter.ArenaManager.RequestGroupMember()
        return
    end

    self.IsShow = true
    self.GameObject:SetActive(true)

    XEventManager.AddEventListener(XEventId.EVENT_ARENA_MAIN_INFO, self.RefreshMainInfo, self)

    XDataCenter.ArenaManager.RequestGroupMember()
    self:Refresh()
end

function XUiPanelActive:Hide()
    if not self.IsShow then
        return
    end

    self.IsShow = false
    self.GameObject:SetActive(false)

    XEventManager.RemoveEventListener(XEventId.EVENT_ARENA_MAIN_INFO, self.RefreshMainInfo, self)
end

function XUiPanelActive:Refresh()
    local challengeCfg = XDataCenter.ArenaManager.GetCurChallengeCfg()
    if challengeCfg then
        self.TxtLevelRange.text = CS.XTextManager.GetText("ArenaPlayerLevelRange", challengeCfg.MinLv, challengeCfg.MaxLv)
        self.TxtArenaRegion.text = challengeCfg.Name
    end

    local arenaLevel = XDataCenter.ArenaManager.GetCurArenaLevel()
    local arenaLevelCfg = XArenaConfigs.GetArenaLevelCfgByLevel(arenaLevel)
    if arenaLevelCfg then
        self.RImgArenaLevel:SetRawImage(arenaLevelCfg.Icon)
    end

    XCountDown.BindTimer(self.TxtCountDownTime.gameObject, XArenaConfigs.ArenaTimerName, function(v)
        self.TxtCountDownTime.text = CS.XTextManager.GetText("ArenaActivityEndCountDown", XUiHelper.GetTime(v, XUiHelper.TimeFormatType.CHALLENGE))
    end)
end

function XUiPanelActive:UnBindTimer()
    XCountDown.UnBindTimer(self.TxtCountDownTime.gameObject, XArenaConfigs.ArenaTimerName)
end

function XUiPanelActive:RefreshMainInfo()
    if not self.GameObject:Exist() then
        return
    end

    self:RefreshSelfInfo()
    self:RefreshTeamInfo()
    self:RefreshArenaPlayerRank()
end

-- 自身
function XUiPanelActive:RefreshSelfInfo()
    local wave = XDataCenter.ArenaManager.GetWaveRate()
    local selfInfo = XDataCenter.ArenaManager.GetPlayerArenaInfo()
    local rank, region = XDataCenter.ArenaManager.GetPlayerArenaRankAndRegion()
    local challengeCfg = XDataCenter.ArenaManager.GetCurChallengeCfg()
    local contributeScore = XDataCenter.ArenaManager.GetContributeScoreByCfg(rank, challengeCfg, selfInfo.Point)
    local sumContributeScore = XDataCenter.ArenaManager.GetContributeScore()

    self.TxtWave.text = CS.XTextManager.GetText("ArenaWaveRate", wave)
    self.TxtSelfNickname.text = selfInfo.Name
    self.TxtPoint.text = selfInfo.Point
    self.TxtRank.text = "No." .. rank
    self.TxtRankRange.text = XArenaConfigs.GetRankRegionText(region)
    XUiPLayerHead.InitPortrait(selfInfo.CurrHeadPortraitId, selfInfo.CurrHeadFrameId, self.Head)

    if sumContributeScore >= CS.XGame.Config:GetInt("ArenaProtectContributeScore") then
        self.PanelContribute.gameObject:SetActiveEx(false)
        self.PanelContributeActivation.gameObject:SetActiveEx(true)
    else        
        local max =  CS.XGame.Config:GetInt("ArenaMaxContributeScore")

        self.TxtSumNumber.text = sumContributeScore
        self.ImgJd.fillAmount = sumContributeScore / max
        self.TxtMaxNumber.text =  "/" .. max
        self.TxtNumberDesc.text = CS.XTextManager.GetText("ContributeScoreNumberDesc", max)
        self.PanelContribute.gameObject:SetActiveEx(true)
        self.PanelContributeActivation.gameObject:SetActiveEx(false)
    end
    XUiArenaContributeScore.Refresh(self.TxtNumber, contributeScore, selfInfo.Point, "000000FF")
end

-- 队伍
function XUiPanelActive:RefreshTeamInfo()
    self.TxtTeamPoint.text = XDataCenter.ArenaManager.GetArenaTeamTotalPoint()
    local teamMemberList = XDataCenter.ArenaManager.GetPlayerArenaTeamMemberInfo()
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



function XUiPanelActive:RefreshArenaPlayerRank()
    local challengeCfg = XDataCenter.ArenaManager.GetCurChallengeCfg()
    local rankData = XDataCenter.ArenaManager.GetPlayerArenaRankList()

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
    local playerIndex = 1

    -- 晋级区
    if challengeCfg.DanUpRank > 0 then
        self:AddTitle(titleIndex, challengeCfg.UpRewardId)
        for i, info in ipairs(rankData.UpList) do
            self:AddPlayer(playerIndex, info, i)
            playerIndex = playerIndex + 1
        end
    end

    -- 保级区
    titleIndex = titleIndex + 1
    self:AddTitle(titleIndex, challengeCfg.KeepRewardId)
    for i, info in ipairs(rankData.KeepList) do
        self:AddPlayer(playerIndex, info, i)
        playerIndex = playerIndex + 1
    end

    -- 降级区
    if challengeCfg.DanDownRank > 0 then
        titleIndex = titleIndex + 1
        self:AddTitle(titleIndex, challengeCfg.DownRewardId)
        for i, info in ipairs(rankData.DownList) do
            self:AddPlayer(playerIndex, info, i)
            playerIndex = playerIndex + 1
        end
    end
end

function XUiPanelActive:AddTitle(rankRegion, rewardId)
    local grid = self.GridTitleCache[rankRegion]
    if not grid then
        local go = CS.UnityEngine.GameObject.Instantiate(self.GridTitle.gameObject)
        grid = go.transform
        grid:SetParent(self.PanelContent, false)
        table.insert(self.GridTitleCache, grid)
    end
    grid.gameObject:SetActive(true)

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
            --从Tips的ui跳转需要关闭Tips的UI
            XLuaUiManager.Open("UiCharacterDetail", list[1].TemplateId)
        elseif goodsShowParams.RewardType == XRewardManager.XRewardType.Equip then
            XLuaUiManager.Open("UiEquipDetail", list[1].TemplateId, true)
            --从Tips的ui跳转需要关闭Tips的UI
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
    self.RootUi:SetUiSprite(rewardIcon, iconPath)
    rewardCount.text = rewards[1].Count
end

function XUiPanelActive:AddPlayer(index, playerInfo, regionIndex)
    local xUiArenaGrid = self.GridPlayerCache[index]
    if not xUiArenaGrid then
        local grid = CS.UnityEngine.GameObject.Instantiate(self.GridPlayer.gameObject)
        grid.transform:SetParent(self.PanelContent, false)
        xUiArenaGrid = XUiArenaGrid.New(grid)
        table.insert(self.GridPlayerCache, xUiArenaGrid)
    end

    xUiArenaGrid:Refresh(index, playerInfo, regionIndex)
    xUiArenaGrid:SetSiblingIndex(self.SiblingIndex - 1)
    self.SiblingIndex = self.SiblingIndex + 1
end

-- 红点
function XUiPanelActive:OnCheckTaskNews(count)
    if self.ImgRedLegion then
        self.ImgRedLegion.gameObject:SetActive(count >= 0)
    end
end

return XUiPanelActive