---@class XUiPanelBossEnter : XUiNode
---@field Parent XUiFubenBossSingle
local XUiPanelBossEnter = XClass(XUiNode, "XUiPanelBossEnter")
local XUiPanelScoreInfo = require("XUi/XUiFubenBossSingle/XUiPanelScoreInfo")
local XUiPanelGroupInfo = require("XUi/XUiFubenBossSingle/XUiPanelGroupInfo")
local XUiGridBossRankReward = require("XUi/XUiFubenBossSingle/XUiGridBossRankReward")

local FUBEN_BOSS_SINGLE_TAG = 2

function XUiPanelBossEnter:OnStart()
    self._CurScoreRewardId = -1
    self._GridRewardList = {}
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
    XUiHelper.RegisterClickEvent(self, self.BtnShop, self.OnBtnShopClick, true)
    XUiHelper.RegisterClickEvent(self, self.BtnTrial, self.OnBtnOpenTrialClick, true)
    XUiHelper.RegisterClickEvent(self, self.GridBossRankReward, self.OnBtnGridBossRankRewardClick, true)
end

function XUiPanelBossEnter:_Init()
    local bossSingleData = self.Parent:GetBossSingleData()
    local rankLevelCfg = XDataCenter.FubenBossSingleManager.GetRankLevelCfgByType(bossSingleData.LevelType)
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
    ---@type XUiGridBossRankReward
    self.RankGrid = XUiGridBossRankReward.New(self.GridBossRankReward, self, self.Parent)
    self.Parent:PlayAnimation("AnimScoreInfoDisable")
    self.ScoreInfo:Close()
    self.GroupInfo:Close()
    self.RankGrid:Close()
end

function XUiPanelBossEnter:_InitRankPanel(bossSingleData)
    local levelType = bossSingleData.LevelType    

    if not XDataCenter.FubenBossSingleManager.CheckHasRankData(levelType) then
        self.PanelRankEmpty.gameObject:SetActiveEx(true)
        self.PanelRankInfo.gameObject:SetActiveEx(false)
        self.TxtRankEmpty.text = XUiHelper.GetText("FubenBossSingleRankEmpty")
    else
        self.PanelRankEmpty.gameObject:SetActiveEx(false)
        self.PanelRankInfo.gameObject:SetActiveEx(true)
    end
end

function XUiPanelBossEnter:Refresh(isRefresh, isSync)
    self:CheckRedPoint()
    
    local bossSingleData = self.Parent:GetBossSingleData()
    -- 仅终极区显示囚笼体验入口
    local bossTrialEnable = bossSingleData.LevelType == XFubenBossSingleConfigs.LevelType.Extreme
    if isRefresh then
        local allCount = XDataCenter.FubenBossSingleManager.GetChallengeCount()
        local numText = CS.XTextManager.GetText("BossSingleChallengeCount", allCount - bossSingleData.ChallengeCount, allCount)
        
        self.TxtLeftCount.text = numText
        self.TxtScore.text = bossSingleData.TotalScore
        
        self:_RefreshBossRank()
        self:_RefreshRewardInfo()
        self:_RefreshRankInfo()
        
        local isInLevelTypeHigh = XDataCenter.FubenBossSingleManager.IsInLevelTypeHigh()
        local isChooseLevelTypeConditionOk = XDataCenter.FubenBossSingleManager.IsChooseLevelTypeConditionOk()

        self.PanelChooseLevelConditionOk.gameObject:SetActiveEx(isInLevelTypeHigh and isChooseLevelTypeConditionOk)
        self.PanelChooseLevelConditionBad.gameObject:SetActiveEx(isInLevelTypeHigh and not isChooseLevelTypeConditionOk)
    end
    
    if not isSync then
        self.Parent:PlayAnimation("AnimEnable1")
    end

    self.BtnTrial.gameObject:SetActiveEx(bossTrialEnable)
end

function XUiPanelBossEnter:_CheckCurrentRank(config, myLevelType, myRankNum, totalCount)
    if not config then
        return false
    end

    if not myLevelType or not myRankNum or not totalCount then
        return false
    end 
    if myLevelType ~= config.LevelType then
        return false
    end
    if myRankNum >= 1 and totalCount > 0 then
        myRankNum = myRankNum / totalCount
    end

    return myRankNum > config.MinRank and myRankNum <= config.MaxRank
end

function XUiPanelBossEnter:_RefreshBossRank()
    local bossSingleData = self.Parent:GetBossSingleData()
    if not XDataCenter.FubenBossSingleManager.GetRankIsOpenByType(bossSingleData.LevelType) 
        or not XDataCenter.FubenBossSingleManager.CheckHasRankData(bossSingleData.LevelType) then
        self.TxtRank.gameObject:SetActiveEx(false)
        self.TxtNoneRank.gameObject:SetActiveEx(true)
    else
        local rank = XDataCenter.FubenBossSingleManager.GetSelfRank()
        local totalRank = XDataCenter.FubenBossSingleManager.GetSelfTotalRank()
        local maxCount = XDataCenter.FubenBossSingleManager.MAX_RANK_COUNT
        if rank <= maxCount and rank > 0 then
            self.TxtRank.text = math.floor(rank)
            self.TxtRank.gameObject:SetActiveEx(true)
            self.TxtNoneRank.gameObject:SetActiveEx(false)
        else
            if not totalRank or totalRank <= 0 or rank <= 0 then
                self.TxtRank.gameObject:SetActiveEx(false)
                self.TxtNoneRank.gameObject:SetActiveEx(true)
            else
                self.TxtRank.gameObject:SetActiveEx(true)
                self.TxtNoneRank.gameObject:SetActiveEx(false)
                local num = math.ceil(rank / totalRank * 100)
                if num < 1 then
                    num = 1
                end

                self.TxtRank.text = XUiHelper.GetText("BossSinglePrecentDesc", num)
            end
        end
    end
end

function XUiPanelBossEnter:_RefreshRankInfo()
    local levelType = self.Parent:GetBossSingleData().LevelType    

    if not XDataCenter.FubenBossSingleManager.CheckHasRankData(levelType) then
        return
    end
    XDataCenter.FubenBossSingleManager.GetRankData(function(rankData)  
        if not rankData then
            return
        end
        
        local config = nil
        local configs = XDataCenter.FubenBossSingleManager.GetRankRewardCfg(levelType)

        for i = 1, #configs do
            if self:_CheckCurrentRank(configs[i], levelType, rankData.MineRankNum, rankData.TotalCount) then
                config = configs[i]
            end
        end
    
        config = config or configs[#configs]
    
        self.RankGrid:Open()
        self.RankGrid:Refresh(config, false, Handler(self, self.OnBtnGridBossRankRewardClick))
    end, levelType)
end

function XUiPanelBossEnter:_RefreshRewardInfo()
    local scoreReardCfg = XDataCenter.FubenBossSingleManager.GetCurScoreRewardCfg()
    local rewardList = {}

    if scoreReardCfg then
        local needScore = CS.XTextManager.GetText("BossSingleScore", scoreReardCfg.Score)
        self.TxtReward.text = needScore
        rewardList = XRewardManager.GetRewardList(scoreReardCfg.RewardId)
        self.BtnReward.gameObject:SetActiveEx(true)
        self.PanelNoneReward.gameObject:SetActiveEx(false)
    else
        local needScore = CS.XTextManager.GetText("BossSingleNoNeedScore")
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

function XUiPanelBossEnter:_ShowRankRewardPanel(rankData)
    local levelType = XDataCenter.FubenBossSingleManager.GetBoosSingleData().LevelType
    local rank = {
        MylevelType = levelType,
        MineRankNum = rankData.MineRankNum,
        HistoryMaxRankNum = rankData.HistoryMaxRankNum,
        TotalCount = rankData.TotalCount,
    }

    self.Parent:ShowRankRewardPanel(levelType, rank)
end

function XUiPanelBossEnter:ShowBossGroupInfo(groupId)
    self.GroupInfo:SetGroupId(groupId)
    self.GroupInfo:Open()
end

function XUiPanelBossEnter:OnSyncBossRank()
    self:_RefreshBossRank()
end

function XUiPanelBossEnter:OnBtnRankClick()
    local levelType = self.Parent:GetBossSingleData().LevelType
    local func = function()
        self.Parent:ShowBossRank()
    end

    if not XDataCenter.FubenBossSingleManager.CheckHasRankData(levelType) then
        return
    end

    XDataCenter.FubenBossSingleManager.GetRankData(func, levelType)
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

function XUiPanelBossEnter:OnBtnGridBossRankRewardClick()
    local levelType = self.Parent:GetBossSingleData().LevelType
    local func = function(rankData)
        self:_ShowRankRewardPanel(rankData)
    end

    if not XDataCenter.FubenBossSingleManager.CheckHasRankData(levelType) then
        return
    end
    XDataCenter.FubenBossSingleManager.GetRankData(func, levelType)
end

-- 红点
function XUiPanelBossEnter:OnCheckRewardNews(count)
    if self.ImgRedHint then
        self.ImgRedHint.gameObject:SetActiveEx(count > 0)
    end
end

return XUiPanelBossEnter