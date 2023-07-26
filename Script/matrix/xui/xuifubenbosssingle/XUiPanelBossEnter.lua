local XUiPanelBossEnter = XClass(nil, "XUiPanelBossEnter")
local XUiPanelScoreInfo = require("XUi/XUiFubenBossSingle/XUiPanelScoreInfo")
local XUiPanelGroupInfo = require("XUi/XUiFubenBossSingle/XUiPanelGroupInfo")

function XUiPanelBossEnter:Ctor(rootUi, ui, bossSingleData)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.BossSingleData = bossSingleData
    self.CurScoreRewardId = -1
    self.RootUi = rootUi
    self.GridRewardList = {}
    XTool.InitUiObject(self)
    self:AutoAddListener()
    self:RegisterRedPointEvent()
    self:Init()
end

function XUiPanelBossEnter:CheckRedPoint()
    if self.EventId then
        XRedPointManager.Check(self.EventId)
    end
end

function XUiPanelBossEnter:RegisterRedPointEvent()
    self.EventId = XRedPointManager.AddRedPointEvent(self.ImgRedHint, self.OnCheckRewardNews, self, { XRedPointConditions.Types.CONDITION_BOSS_SINGLE_REWARD })
    XEventManager.AddEventListener(XEventId.EVENT_FUBEN_SINGLE_BOSS_RANK_SYNC, self.OnSyncBossRank, self)
end

function XUiPanelBossEnter:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_FUBEN_SINGLE_BOSS_RANK_SYNC, self.OnSyncBossRank, self)
end

function XUiPanelBossEnter:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiPanelBossEnter:RegisterClickEvent函数参数错误：参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiPanelBossEnter:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiPanelBossEnter:AutoAddListener()
    self:RegisterClickEvent(self.BtnActDesc, self.OnBtnActDescClick)
    self:RegisterClickEvent(self.BtnRank, self.OnBtnRankClick)
    self:RegisterClickEvent(self.BtnReward, self.OnBtnRewardClick)
    self:RegisterClickEvent(self.BtnShop, self.OnBtnShopClick)
    self:RegisterClickEvent(self.BtnTrial, self.OnBtnOpenTrialClick)
end

function XUiPanelBossEnter:Init()
    local rankLevelCfg = XDataCenter.FubenBossSingleManager.GetRankLevelCfgByType(self.BossSingleData.LevelType)

    self.RootUi:SetUiSprite(self.ImgLevelIcon, rankLevelCfg.Icon)
    self.TxtLevelName.text = rankLevelCfg.LevelName
    local text = CS.XTextManager.GetText("BossSingleRankDesc", rankLevelCfg.MinPlayerLevel, rankLevelCfg.MaxPlayerLevel)
    self.TxtLevel.text = "（" .. text .. "）"
    self.GridReward.gameObject:SetActiveEx(false)
    self.ScoreInfo = XUiPanelScoreInfo.New(self.RootUi, self.PanelScoreInfo, self.BossSingleData)
    self.GroupInfo = XUiPanelGroupInfo.New(self.RootUi, self.PanelGroupInfo)
    self.RootUi:PlayAnimation("AnimScoreInfoDisable")
    self.ScoreInfo:HidePanel()
    self.GroupInfo:HidePanel()
    self:ShowPanel(true, self.BossSingleData)
end

function XUiPanelBossEnter:OnSyncBossRank()
    if not XDataCenter.FubenBossSingleManager.GetRankIsOpenByType(self.BossSingleData.LevelType) then
        self.TxtRank.gameObject:SetActiveEx(false)
    else
        local rank = XDataCenter.FubenBossSingleManager.GetSelfRank()
        local totalRank = XDataCenter.FubenBossSingleManager.GetSelfTotalRank()
        local maxCount = XDataCenter.FubenBossSingleManager.MAX_RANK_COUNT
        if rank <= maxCount and rank > 0 then
            self.TxtRank.text = math.floor(rank)
        else
            if not totalRank or totalRank <= 0 or rank <= 0 then
                self.TxtRank.text = CS.XTextManager.GetText("None")
            else
                local num = math.floor(rank / totalRank * 100)
                if num < 1 then
                    num = 1
                end

                self.TxtRank.text = CS.XTextManager.GetText("BossSinglePrecentDesc", num)
            end
        end
    end
end

function XUiPanelBossEnter:ShowPanel(refresh, bossSingleData, isAutoFight, isSync)
    if bossSingleData then
        self.BossSingleData = bossSingleData
    end

    self:CheckRedPoint()
    if refresh then
        local allCount = XDataCenter.FubenBossSingleManager.GetChallengeCount()
        local numText = CS.XTextManager.GetText("BossSingleChallengeCount", self.BossSingleData.ChallengeCount, allCount)

        self.TxtLeftCount.text = numText
        self.TxtScore.text = self.BossSingleData.TotalScore
        
        self:OnSyncBossRank()
        self:SetRewardInfo()

        local isInLevelTypeHigh = XDataCenter.FubenBossSingleManager.IsInLevelTypeHigh()
        local isChooseLevelTypeConditionOk = XDataCenter.FubenBossSingleManager.IsChooseLevelTypeConditionOk()
        self.PanelChooseLevelConditionOk.gameObject:SetActiveEx(isInLevelTypeHigh and isChooseLevelTypeConditionOk)
        self.PanelChooseLevelConditionBad.gameObject:SetActiveEx(isInLevelTypeHigh and not isChooseLevelTypeConditionOk)
    end

    if not isAutoFight then
        if not isSync then
            self.RootUi:PlayAnimation("AnimEnable1")
        end
        self.GameObject:SetActiveEx(true)
    end

    -- 仅终极区显示囚笼体验入口
    local bossTrialEnable = self.BossSingleData.LevelType == XFubenBossSingleConfigs.LevelType.Extreme
    self.BtnTrial.gameObject:SetActive(bossTrialEnable)
end

function XUiPanelBossEnter:SetRewardInfo()
    local scoreReardCfg = XDataCenter.FubenBossSingleManager.GetCurScoreRewardCfg()
    local rewardList = {}

    if scoreReardCfg then
        local needScore = CS.XTextManager.GetText("BossSingleScore", scoreReardCfg.Score)
        self.TxtReward.text = needScore
        rewardList = XRewardManager.GetRewardList(scoreReardCfg.RewardId)
    else
        local needScore = CS.XTextManager.GetText("BossSingleNoNeedScore")
        self.TxtReward.text = needScore
    end

    if scoreReardCfg and self.CurScoreRewardId == scoreReardCfg.Id then
        return
    end

    self.CurScoreRewardId = scoreReardCfg and scoreReardCfg.Id or -1

    for i = 1, #rewardList do
        local grid = self.GridRewardList[i]
        if not grid then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridReward)
            grid = XUiGridCommon.New(self.RootUi, ui)
            grid.Transform:SetParent(self.PanelRewardContent, false)
            self.GridRewardList[i] = grid
        end

        grid:Refresh(rewardList[i])
        grid.GameObject:SetActiveEx(true)
    end

    for i = #rewardList + 1, #self.GridRewardList do
        self.GridRewardList[i].GameObject:SetActiveEx(false)
    end
end

function XUiPanelBossEnter:HidePanel()
    self.GameObject:SetActiveEx(false)
end

function XUiPanelBossEnter:OnBtnActDescClick()
    local text = CS.XTextManager.GetText("BossSingleDesc")
    XUiManager.UiFubenDialogTip("", text or "")
end

function XUiPanelBossEnter:OnBtnRankClick()
    local func = function()
        self.RootUi:ShowBossRank(self.BossSingleData.LevelType, self.BossSingleData.RankPlatform)
    end
    XDataCenter.FubenBossSingleManager.GetRankData(func, self.BossSingleData.LevelType)
end

function XUiPanelBossEnter:OnBtnRewardClick()
    self.ScoreInfo:ShowPanel(self.BossSingleData)
    self.RootUi:PlayAnimation("AnimScoreInfoEnable")
end

function XUiPanelBossEnter:OnBtnShopClick()
    XLuaUiManager.Open("UiShop", XShopManager.ShopType.Boss)
end

function XUiPanelBossEnter:OnBtnOpenTrialClick()
    XLuaUiManager.Open("UiFubenBossSingleTrial")        
end

function XUiPanelBossEnter:ShowBossGroupInfo(groupId)
    self.GroupInfo:ShowBossGroupInfo(groupId)
end

-- 红点
function XUiPanelBossEnter:OnCheckRewardNews(count)
    if self.ImgRedHint then
        self.ImgRedHint.gameObject:SetActiveEx(count > 0)
    end
end

return XUiPanelBossEnter