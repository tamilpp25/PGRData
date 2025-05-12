
---@class XUiBlackRockChessVictorySettlement : XLuaUi
---@field _Control XBlackRockChessControl
local XUiBlackRockChessVictorySettlement = XLuaUiManager.Register(XLuaUi, "UiBlackRockChessVictorySettlement")

function XUiBlackRockChessVictorySettlement:OnAwake()
    self.Items = {}
    self:InitCb()
end

function XUiBlackRockChessVictorySettlement:OnStart(stageId, settle)
    self.StageId = stageId
    self.Settle = settle
    self._UiObject = {}

    local index = settle.IsWin and 1 or 2
    self.FullScreenBackground:LoadPrefab(self._Control:GetClientConfig("SettleBgPrefab", index))

    local go = self.SafeAreaContentPane:LoadPrefab(self._Control:GetClientConfig("SettlePanelPrefab", index))
    if XTool.UObjIsNil(go) then
        return
    else
        XUiHelper.InitUiClass(self._UiObject, go)
        local animEnable = self._UiObject.Transform:FindTransform("AnimEnable")
        if animEnable then
            animEnable:PlayTimelineAnimation()
        end
    end

    self._UiObject.GridCommon.gameObject:SetActiveEx(false)
    self:RefreshReward()
    self:RefreshView()
end

function XUiBlackRockChessVictorySettlement:OnDestroy()
    self:StopAllTweener()
end

function XUiBlackRockChessVictorySettlement:InitCb()
    self.BtnClose.CallBack = function()
        self:OnBtnCloseClick()
    end
end

function XUiBlackRockChessVictorySettlement:RefreshReward()
    local hasReward = false
    local starLvRewards, repeatRewards
    if not XTool.IsTableEmpty(self.Settle.RewardGoodsList) then
        starLvRewards = XRewardManager.MergeAndSortRewardGoodsList(self.Settle.RewardGoodsList)
    end
    if not XTool.IsTableEmpty(self.Settle.SettleScoreReward) then
        repeatRewards = XRewardManager.MergeAndSortRewardGoodsList(self.Settle.SettleScoreReward)
    end
    local list = XTool.MergeArray(starLvRewards, repeatRewards)
    local repeatIndex = starLvRewards and (#starLvRewards + 1) or 0
    local index = 1
    hasReward = hasReward or #list > 0
    ---@param grid XUiGridCommon
    XUiHelper.CreateTemplates(self, self.Items, list, require("XUi/XUiObtain/XUiGridCommon").New, self._UiObject.GridCommon, self._UiObject.PanelDropContent, function(grid, data)
        grid:Refresh(data, nil, nil, false)
        grid:SetPanelFirst(false)
        grid:SetPanelTag(index >= repeatIndex)
        self:PlayRewardTween(index, grid)
        index = index + 1
    end)
    self._UiObject.PanelNoReward.gameObject:SetActiveEx(not hasReward)
end

function XUiBlackRockChessVictorySettlement:RefreshView()
    self._UiObject.TxtNodeCount.text = self.Settle.NodeCount
    self._UiObject.TxtNodeScore.text = string.format("+%s", self.Settle.NodeScore)
    self._UiObject.TxtCostRound.text = self.Settle.RoundCount
    self._UiObject.TxtCostRoundScore.text = string.format("%s", self.Settle.RoundScore)
    self._UiObject.TxtKill.text = self.Settle.KillCount
    self._UiObject.TxtKillScore.text = string.format("+%s", self.Settle.KillScore)
    self._UiObject.TxtReviveTimes.text = self.Settle.ReviveCount
    self._UiObject.TxtReviveTimesScore.text = string.format("+%s", self.Settle.ReviveScore)
    self._UiObject.TxtScore.text = self.Settle.Score
    self._UiObject.TagNew.gameObject:SetActiveEx(self.Settle.IsNewRecord)

    if self._UiObject.GridStar then
        local star = self.Settle.Star
        for i = 1, 3 do
            local go = i == 1 and self._UiObject.GridStar or XUiHelper.Instantiate(self._UiObject.GridStar, self._UiObject.GridStar.parent)
            local uiObject = {}
            XUiHelper.InitUiClass(uiObject, go)
            uiObject.ImgStarOn.gameObject:SetActiveEx(i <= star)
            uiObject.ImgStarOff.gameObject:SetActiveEx(i > star)
            local canvasGroup = uiObject.Transform:GetComponent("CanvasGroup")
            self:PlayStarTween(i, canvasGroup)
        end
    end
end

---@return XUiGridCommon
function XUiBlackRockChessVictorySettlement:GetFirstPassGrid()
    local ui = XUiHelper.Instantiate(self._UiObject.GridCommon, self._UiObject.PanelDropContent)
    local grid = require("XUi/XUiObtain/XUiGridCommon").New(self, ui)
    grid:SetProxyClickFunc(handler(self, self.OnClickUncommon))
    grid.GameObject:SetActiveEx(true)
    grid:SetPanelFirst(true)
    grid:SetPanelTag(false)
    return grid
end

function XUiBlackRockChessVictorySettlement:OnClickUncommon()
    
end

function XUiBlackRockChessVictorySettlement:OnBtnCloseClick()
    if not XTool.IsNumberValid(self.StageId) then
        return
    end
    self._Control:ExitStage(self.StageId)
    XLuaUiManager.SafeClose("UiBlackRockChessBubbleSkill")
    XLuaUiManager.SafeClose("UiBlackRockChessBattle")
    XLuaUiManager.SafeClose("UiBlackRockChessVictorySettlement")
end

function XUiBlackRockChessVictorySettlement:PlayRewardTween(index, grid)
    local timerId = XScheduleManager.ScheduleOnce(function()
        grid.Transform:FindTransform("Enable"):PlayTimelineAnimation()
    end, (index - 1) * 150)
    grid.Transform:GetComponent("CanvasGroup").alpha = 0
    self:_AddTimerId(timerId)
end

function XUiBlackRockChessVictorySettlement:PlayStarTween(index, canvasGroup)
    local timerId = XScheduleManager.ScheduleOnce(function()
        canvasGroup.alpha = 1
    end, (index - 1) * 150)
    canvasGroup.alpha = 0
    self:_AddTimerId(timerId)
end

return XUiBlackRockChessVictorySettlement