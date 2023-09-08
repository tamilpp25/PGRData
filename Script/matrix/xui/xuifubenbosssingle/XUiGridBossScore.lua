---@class XUiGridBossScore : XUiNode
local XUiGridBossScore = XClass(XUiNode, "XUiGridBossScore")

function XUiGridBossScore:OnStart(rootUi)
    self._RootUi = rootUi
    self._GridRewardList = {}
    self:_RegisterButtonListeners()
end

function XUiGridBossScore:OnEnable()
    self:_Refresh()
end

function XUiGridBossScore:SetData(scoreCfg, totalScore)
    self._TotalScore = totalScore
    self._ScoreCfg = scoreCfg
end

function XUiGridBossScore:_RegisterButtonListeners()
    XUiHelper.RegisterClickEvent(self, self.BtnReceive, self.OnBtnReceiveClick, true)
end

function XUiGridBossScore:_Refresh()
    if not self._TotalScore or not self._ScoreCfg then
        return
    end

    local scoreCfg = self._ScoreCfg
    local isGet = XDataCenter.FubenBossSingleManager.CheckRewardGet(scoreCfg.Id)
    local rewardList = XRewardManager.GetRewardList(scoreCfg.RewardId)
    
    self.GridReward.gameObject:SetActiveEx(false)
    self.TxtScore.text = scoreCfg.Score
    self.PanelAlreadyGet.gameObject:SetActive(isGet)
    self.BtnReceive.gameObject:SetActive(not isGet)

    local canGet = self._TotalScore >= self._ScoreCfg.Score
    if not canGet then
        self.BtnReceive:SetButtonState(CS.UiButtonState.Disable)
    else
        self.BtnReceive:SetButtonState(CS.UiButtonState.Normal)
    end

    for i = 1, #rewardList do
        local grid = self._GridRewardList[i]
        if not grid then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridReward)
            grid = XUiGridCommon.New(self._RootUi, ui)
            grid.Transform:SetParent(self.PanelRewardContent, false)
            self._GridRewardList[i] = grid
        end

        grid:Refresh(rewardList[i])
        grid.GameObject:SetActive(true)
    end

    for i = #rewardList + 1, #self._GridRewardList do
        self._GridRewardList[i].GameObject:SetActive(false)
    end
end

function XUiGridBossScore:OnBtnReceiveClick()
    local canGet = self._TotalScore >= self._ScoreCfg.Score
    if not canGet then
        XUiManager.TipText("BossSingleCannotReward")
        return
    end

    XDataCenter.FubenBossSingleManager.GetRankRewardReq(self._ScoreCfg.Id, function(rewards)
        if rewards and #rewards > 0 then
            XUiManager.OpenUiObtain(rewards)
        end

        XEventManager.DispatchEvent(XEventId.EVENT_BOSS_SINGLE_GET_REWARD)
        self.PanelAlreadyGet.gameObject:SetActive(true)
        self.BtnReceive.gameObject:SetActive(false)
    end)
end

return XUiGridBossScore