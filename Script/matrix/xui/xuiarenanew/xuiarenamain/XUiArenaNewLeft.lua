local XUiArenaNewGridTitle = require("XUi/XUiArenaNew/XUiArenaMain/XUiArenaNewGridTitle")
local XUiArenaNewGridPlayer = require("XUi/XUiArenaNew/XUiArenaMain/XUiArenaNewGridPlayer")

---@class XUiArenaNewLeft : XUiNode
---@field BtnRankDetail XUiComponent.XUiButton
---@field BtnDetail XUiComponent.XUiButton
---@field BtnScoreRank XUiComponent.XUiButton
---@field BtnSelfPlayerScore XUiComponent.XUiButton
---@field ImgRank UnityEngine.UI.RawImage
---@field TxtRank UnityEngine.UI.Text
---@field TxtLvNum UnityEngine.UI.Text
---@field TxtTimeNum UnityEngine.UI.Text
---@field RankContent UnityEngine.RectTransform
---@field GridTitle UnityEngine.RectTransform
---@field GridPlayer UnityEngine.RectTransform
---@field TxtTips UnityEngine.UI.Text
---@field TxtAdd UnityEngine.UI.Text
---@field TxtContributeTips UnityEngine.UI.Text
---@field TxtContributeNow UnityEngine.UI.Text
---@field ImgBarAdd UnityEngine.UI.Image
---@field ImgBar UnityEngine.UI.Image
---@field GridSelfPlayer UnityEngine.RectTransform
---@field _Control XArenaControl
local XUiArenaNewLeft = XClass(XUiNode, "XUiArenaNewLeft")

-- region 生命周期

function XUiArenaNewLeft:OnStart(groupData)
    ---@type XUiArenaNewGridTitle[]
    self._TitleGridCache = {}
    ---@type XUiArenaNewGridPlayer[]
    self._PlayerGridCache = {}
    ---@type XArenaGroupDataBase
    self._GroupData = groupData
    self._ChallengeTimer = nil
    ---@type XUiArenaNewGridPlayer
    self._SelfPlayerGridUi = nil

    self:_InitUi()
    self:_RegisterButtonClicks()
end

function XUiArenaNewLeft:OnEnable()
    self:Refresh()
    self:_RegisterSchedules()
end

function XUiArenaNewLeft:OnDisable()
    self:_RemoveSchedules()
end

-- endregion

---@param groupData XArenaGroupDataBase
function XUiArenaNewLeft:Refresh(groupData)
    self._GroupData = groupData or self._GroupData

    self.BtnScoreRank.gameObject:SetActiveEx(not self._Control:IsInActivityOverStatus())
    if self._GroupData then
        self:_RefreshChallengeTimer()
        self:_RefreshPlayerRankList()
        self:_RefreshArenaInfo()
        self:_RefreshSelfRank()
        self:_RefreshScoreBar()
    end
end

function XUiArenaNewLeft:GetArenaLevel()
    if self._GroupData then
        return self._GroupData:GetArenaLevel()
    end

    return 0
end

function XUiArenaNewLeft:GetChallengeId()
    if self._GroupData then
        return self._GroupData:GetChallengeId()
    end

    return 0
end

-- region 按钮事件

function XUiArenaNewLeft:OnBtnRankDetailClick()
    self:_OpenTipsUi(false)
end

function XUiArenaNewLeft:OnBtnDetailClick()
    self:_OpenTipsUi(true)
end

function XUiArenaNewLeft:OnBtnScoreRankClick()
    XLuaUiManager.Open("UiArenaTeamRank", self._GroupData)
    self.Parent:OnShowTips()
end

-- endregion

-- region 私有方法
function XUiArenaNewLeft:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    XUiHelper.RegisterClickEvent(self, self.BtnRankDetail, self.OnBtnRankDetailClick, true)
    XUiHelper.RegisterClickEvent(self, self.BtnDetail, self.OnBtnDetailClick, true)
    XUiHelper.RegisterClickEvent(self, self.BtnScoreRank, self.OnBtnScoreRankClick, true)
    XUiHelper.RegisterClickEvent(self, self.BtnSelfPlayerScore, self.OnBtnRankDetailClick, true)
end

function XUiArenaNewLeft:_RegisterSchedules()
    -- 在此处注册定时器
    self:_RegisterChallengeTimer()
end

function XUiArenaNewLeft:_RemoveSchedules()
    -- 在此处移除定时器
    self:_RemoveChallengeTimer()
end

function XUiArenaNewLeft:_RefreshArenaInfo()
    local challengeId = self._GroupData:GetChallengeId()
    local arenaLevel = self._GroupData:GetArenaLevel()
    
    self.TxtLvNum.text = self._Control:GetCurrentChallengeLevelNotDescStr()
    self.TxtRank.text = self._Control:GetChallengeNameByChallengeId(challengeId)
    self.ImgRank:SetRawImage(self._Control:GetArenaLevelIconById(arenaLevel))
end

function XUiArenaNewLeft:_RefreshSelfRank()
    local playerData = self._GroupData:GetSelfGroupPlayerData()
    local rank = self._GroupData:GetSelfRank()
    local regionType = self._Control:GetRegionTypeByPlayerDataAndRank(playerData, rank)

    if self._SelfPlayerGridUi then
        self._SelfPlayerGridUi:Refresh(regionType, playerData, rank)
        self._SelfPlayerGridUi:Close()
    else
        self._SelfPlayerGridUi = XUiArenaNewGridPlayer.New(self.GridSelfPlayer, self, regionType, playerData, rank)
    end
    self._SelfPlayerGridUi:Open()
    self.TxtTips.text = XUiHelper.GetText("ArenaProtectedNumber", self._Control:GetActivityProtectedScore(),
        self._Control:GetAreaMaxProtectScore())
end

function XUiArenaNewLeft:_RefreshScoreBar()
    if self._Control:IsInActivityOverStatus() then
        if self.PanelContribute then
            self.PanelContribute.gameObject:SetActiveEx(false)
        end
    else
        local rank = self._GroupData:GetSelfRank()
        local playerData = self._GroupData:GetSelfGroupPlayerData()
        local contributeScore = self._Control:GetActivityContributeScore()
        local maxScore = self._Control:GetMaxContributeScore()
        
        if self.PanelContribute then
            self.PanelContribute.gameObject:SetActiveEx(true)
        end
        if playerData and XTool.IsNumberValid(playerData:GetPoint()) then
            local challengeId = self._Control:GetActivityChallengeId()
            local rankScore = self._Control:GetChallengeContributeScoreByIdAndIndex(challengeId, rank)
            
            self.TxtContributeNow.text = XUiHelper.GetText("ArenaContributeScore", contributeScore, maxScore, rankScore)
            self.ImgBarAdd.fillAmount = (contributeScore + rankScore) / maxScore
        else
            self.TxtContributeNow.text = contributeScore .. "/" .. maxScore
            self.ImgBarAdd.fillAmount = 0
        end
        
        self.ImgBar.fillAmount = contributeScore / maxScore
    end
end

function XUiArenaNewLeft:_RefreshPlayerRankList()
    local rankData = self._Control:GetRankDataByGroupPlayerData(self._GroupData)

    for _, grid in pairs(self._TitleGridCache) do
        grid:Close()
    end
    for _, grid in pairs(self._PlayerGridCache) do
        grid:Close()
    end

    local index = 0
    local rankIndex = 0
    for regionType, rankList in pairs(rankData) do
        self:_RefreshRankTitle(regionType, index + rankIndex)
        for _, _ in pairs(rankList) do
            rankIndex = rankIndex + 1
            if rankList[rankIndex] then
                self:_RefreshRankPlayer(rankList[rankIndex], rankIndex, regionType, rankIndex + index)
            end
        end
        index = index + 1
    end
end

function XUiArenaNewLeft:_RefreshRankTitle(regionType, index)
    local titleGrid = self._TitleGridCache[regionType]

    if not titleGrid then
        local titleObject = XUiHelper.Instantiate(self.GridTitle, self.RankContent)

        titleGrid = XUiArenaNewGridTitle.New(titleObject, self, regionType)
        self._TitleGridCache[regionType] = titleGrid
    else
        titleGrid:Refresh(regionType)
    end

    titleGrid.Transform:SetSiblingIndex(index)
    titleGrid:Open()
end

function XUiArenaNewLeft:_RefreshRankPlayer(info, rank, rgeionType, index)
    local playerGrid = self._PlayerGridCache[rank]

    if not playerGrid then
        local playerObject = XUiHelper.Instantiate(self.GridPlayer, self.RankContent)

        playerGrid = XUiArenaNewGridPlayer.New(playerObject, self, rgeionType, info, rank)
        self._PlayerGridCache[rank] = playerGrid
    else
        playerGrid:Refresh(rgeionType, info, rank)
    end

    playerGrid.Transform:SetSiblingIndex(index)
    playerGrid:Open()
end

function XUiArenaNewLeft:_RefreshChallengeTimer()
    self.TxtTimeNum.text = self._Control:GetActivityRemainTimeStr()
end

function XUiArenaNewLeft:_RegisterChallengeTimer()
    self:_RemoveChallengeTimer()
    self._ChallengeTimer = XScheduleManager.ScheduleForever(Handler(self, self._RefreshChallengeTimer),
        XScheduleManager.SECOND)
end

function XUiArenaNewLeft:_RemoveChallengeTimer()
    if self._ChallengeTimer then
        XScheduleManager.UnSchedule(self._ChallengeTimer)
        self._ChallengeTimer = nil
    end
end

function XUiArenaNewLeft:_InitUi()
    self.GridPlayer.gameObject:SetActiveEx(false)
    self.GridTitle.gameObject:SetActiveEx(false)
end

function XUiArenaNewLeft:_OpenTipsUi(isScrollEnd)
    local challengeId = self._GroupData:GetChallengeId()
    local arenaLevel = self._GroupData:GetArenaLevel()
    local waveRate = self._GroupData:GetWaveRate()

    XLuaUiManager.Open("UiArenaContributeTips", challengeId, arenaLevel, waveRate, isScrollEnd)
    self.Parent:OnShowTips()
end

-- endregion

return XUiArenaNewLeft
