local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiPanelBossEnter : XUiNode
---@field Parent XUiFubenBossSingle
---@field _Control XFubenBossSingleControl
local XUiPanelBossEnter = XClass(XUiNode, "XUiPanelBossEnter")
local XUiPanelScoreInfo = require("XUi/XUiFubenBossSingle/XUiPanelScoreInfo")
local XUiPanelGroupInfo = require("XUi/XUiFubenBossSingle/XUiPanelGroupInfo")
local XUiFubenBossSingleMainRank = require("XUi/XUiFubenBossSingle/XUiFubenBossSingleMainRank")
local XUiFubenBossSingleMainRankNew = require("XUi/XUiFubenBossSingle/XUiFubenBossSingleMainRankNew")

function XUiPanelBossEnter:OnStart()
    self._CurScoreRewardId = -1
    self._GridRewardList = {}
    self.GridBossRankReward.gameObject:SetActiveEx(false)
    self._EventId = self:AddRedPointEvent(self.ImgRedHint, self.OnCheckRewardNews, self, { XRedPointConditions.Types.CONDITION_BOSS_SINGLE_REWARD })
    self.BtnTrial:ShowReddot(false)
    self:_RegisterButtonListeners()
    self:_Init()
end

function XUiPanelBossEnter:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_FUBEN_SINGLE_BOSS_RANK_SYNC, self.OnSyncBossRank, self)
end

function XUiPanelBossEnter:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_FUBEN_SINGLE_BOSS_RANK_SYNC, self.OnSyncBossRank, self)
end

function XUiPanelBossEnter:CheckRedPoint()
    if self._EventId then
        XRedPointManager.Check(self._EventId)
    end
end

function XUiPanelBossEnter:_RegisterButtonListeners()
    XUiHelper.RegisterClickEvent(self, self.BtnRank, self.OnBtnRankClick, true)
    XUiHelper.RegisterClickEvent(self, self.BtnReward, self.OnBtnRewardClick, true)
    XUiHelper.RegisterClickEvent(self, self.PanelNoneReward, self.OnBtnRewardClick, true)
    XUiHelper.RegisterClickEvent(self, self.BtnShop, self.OnBtnShopClick, true)
    XUiHelper.RegisterClickEvent(self, self.BtnTrial, self.OnBtnOpenTrialClick, true)
end

function XUiPanelBossEnter:_Init()
    ---@type XBossSingle
    local bossSingleData = self.Parent:GetBossSingleData()
    local levelType = bossSingleData:GetBossSingleLevelType()
    local rankLevelCfg = self._Control:GetRankLevelConfigByType(levelType)
    local text = XUiHelper.GetText("BossSingleRankDesc", rankLevelCfg.MinPlayerLevel, rankLevelCfg.MaxPlayerLevel)

    self:_InitRankPanel(bossSingleData)
    self.Parent:SetUiSprite(self.ImgLevelIcon, rankLevelCfg.Icon)
    self.TxtLevelName.text = rankLevelCfg.LevelName
    self.TxtLevel.text = "（" .. text .. "）"
    self.GridReward.gameObject:SetActiveEx(false)
    ---@type XUiPanelScoreInfo
    self.ScoreInfo = XUiPanelScoreInfo.New(self.PanelScoreInfo, self, self.Parent)
    ---@type XUiPanelGroupInfo
    self.GroupInfo = XUiPanelGroupInfo.New(self.PanelGroupInfo, self, self.Parent)
    self.Parent:PlayAnimation("AnimScoreInfoDisable")
    self.ScoreInfo:Close()
    self.GroupInfo:Close()
end

---@param bossSingleData XBossSingle
function XUiPanelBossEnter:_InitRankPanel(bossSingleData)
    if not bossSingleData:IsNewVersion() then
        self.PanelRank.gameObject:SetActiveEx(true)
        self.PanelRankNew.gameObject:SetActiveEx(false)
        ---@type XUiFubenBossSingleMainRank
        self.RankMain = XUiFubenBossSingleMainRank.New(self.PanelRank, self, self.Parent)
    else
        self.PanelRank.gameObject:SetActiveEx(false)
        self.PanelRankNew.gameObject:SetActiveEx(true)
        ---@type XUiFubenBossSingleMainRankNew
        self.RankMain = XUiFubenBossSingleMainRankNew.New(self.PanelRankNew, self, self.Parent)
    end

    self.RankMain:Init()
end

function XUiPanelBossEnter:Refresh(isRefresh)
    self:CheckRedPoint()
    
    ---@type XBossSingle
    local bossSingleData = self.Parent:GetBossSingleData()
    local levelType = bossSingleData:GetBossSingleLevelType()
    local gradeType = self._Control:GetGradeTypeByLevelType(levelType)
    -- 仅终极区显示囚笼体验入口
    local bossTrialEnable = gradeType == XEnumConst.BossSingle.LevelType.Extreme

    if isRefresh then
        local allCount = self._Control:GetChallengeCount()
        local numText = XUiHelper.GetText("BossSingleChallengeCount", allCount - bossSingleData:GetBossSingleChallengeCount(), allCount)
        
        self.TxtLeftCount.text = numText
        self.TxtScore.text = bossSingleData:GetBossSingleTotalScore()
        
        self:_RefreshBossRank()
        self:_RefreshRewardInfo()
        self:_RefreshRankInfo()
        
        local isInLevelTypeHigh = self._Control:IsInLevelTypeHigh()
        local isInLevelTypeExtreme = self._Control:IsInLevelTypeExtreme()
        local isChooseLevelTypeConditionOk = self._Control:IsChooseLevelTypeConditionOk()

        if self.PanelChooseLevelConditionOk.parent then
            local bottom = self.PanelChooseLevelConditionOk.parent

            bottom.gameObject:SetActiveEx(isInLevelTypeHigh or isInLevelTypeExtreme)
        end

        self.PanelChooseLevelConditionOk.gameObject:SetActiveEx(isInLevelTypeHigh and isChooseLevelTypeConditionOk)
        self.PanelChooseLevelConditionBad.gameObject:SetActiveEx(isInLevelTypeHigh and not isChooseLevelTypeConditionOk)
    end

    self.BtnTrial.gameObject:SetActiveEx(bossTrialEnable)
end

function XUiPanelBossEnter:_RefreshBossRank()
    self.RankMain:RefreshRank()
end

function XUiPanelBossEnter:_RefreshRankInfo()
    self.RankMain:RefreshRankReward()
end

function XUiPanelBossEnter:_RefreshRewardInfo()
    local scoreReardCfg = self._Control:GetCurScoreRewardConfig()
    local rewardList = {}

    if scoreReardCfg then
        local needScore = XUiHelper.GetText("BossSingleScore", scoreReardCfg.Score)
        self.TxtReward.text = needScore
        rewardList = XRewardManager.GetRewardList(scoreReardCfg.RewardId)
        self.BtnReward.gameObject:SetActiveEx(true)
        self.PanelNoneReward.gameObject:SetActiveEx(false)
    else
        local needScore = XUiHelper.GetText("BossSingleNoNeedScore")
        self.TxtReward.text = needScore
        self.BtnReward.gameObject:SetActiveEx(false)
        self.PanelNoneReward.gameObject:SetActiveEx(true)
    end

    if scoreReardCfg and self._CurScoreRewardId == scoreReardCfg.Id then
        return
    end

    self._CurScoreRewardId = scoreReardCfg and scoreReardCfg.Id or -1

    for i = 1, #rewardList do
        local grid = self._GridRewardList[i]
        if not grid then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridReward)
            grid = XUiGridCommon.New(self.Parent, ui)
            grid.Transform:SetParent(self.PanelRewardContent, false)
            self._GridRewardList[i] = grid
        end

        grid:SetProxyClickFunc(Handler(self, self.OnBtnRewardClick))
        grid:Refresh(rewardList[i])
        grid.GameObject:SetActiveEx(true)
    end

    for i = #rewardList + 1, #self._GridRewardList do
        self._GridRewardList[i].GameObject:SetActiveEx(false)
    end
end

function XUiPanelBossEnter:ShowBossGroupInfo(groupId)
    self.GroupInfo:SetGroupId(groupId)
    self.GroupInfo:Open()
end

function XUiPanelBossEnter:OnSyncBossRank()
    self:_RefreshBossRank()
end

function XUiPanelBossEnter:OnBtnRankClick()
    local levelType = self.Parent:GetBossSingleData():GetBossSingleLevelType()

    if not self._Control:CheckHasRankData(levelType) then
        return
    end

    XMVCA.XFubenBossSingle:RequestRankData(function()
        self.Parent:ShowBossRank()
    end, levelType)
end

function XUiPanelBossEnter:OnBtnRewardClick()
    self.ScoreInfo:Open()
    self.Parent:PlayAnimation("AnimScoreInfoEnable")
end

function XUiPanelBossEnter:OnBtnShopClick()
    XLuaUiManager.Open("UiShop", XShopManager.ShopType.Boss)
end

function XUiPanelBossEnter:OnBtnOpenTrialClick()
    XLuaUiManager.Open("UiFubenBossSingleTrial")
end

-- 红点
function XUiPanelBossEnter:OnCheckRewardNews(count)
    if self.ImgRedHint then
        self.ImgRedHint.gameObject:SetActiveEx(count > 0)
    end
    self.PanelNoneReward:ShowReddot(count > 0)
end

return XUiPanelBossEnter