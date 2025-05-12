local XUiGridStageStar = require("XUi/XUiFubenMainLineDetail/XUiGridStageStar")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiPanelStagInfo = XClass(nil, "XUiPanelStagInfo")
local MAX_START = 3

function XUiPanelStagInfo:Ctor(uiRoot, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot
    self.GridList = {}

    XTool.InitUiObject(self)
    self:InitStarPanels()
    self.GridCommon.gameObject:SetActiveEx(false)
end

function XUiPanelStagInfo:InitStarPanels()
    self.GridStarList = {}
    for i = 1, MAX_START do
        local ui = self["GridStageStar" .. i]
        ui.gameObject:SetActiveEx(true)
        local grid = XUiGridStageStar.New(ui)
        self.GridStarList[i] = grid
    end
end

function XUiPanelStagInfo:Show(challengeId, multiplayerMode, checkActive)
    -- if self.StageId == stageId and not checkActive then
    --     self.CanvasGroup.alpha = 0
    --     self.GameObject:SetActiveEx(true)
    --     self.UiRoot:PlayAnimation("StageInfoQieHuan")
    --     return
    -- end

    self.ChallengeId = challengeId
    self.MultiplayerMode = multiplayerMode
    local id = XDataCenter.ArenaOnlineManager.GetStageId(self.ChallengeId)
    self.StageCfg = XDataCenter.FubenManager.GetStageCfg(id)
    self.StarsMap = XDataCenter.ArenaOnlineManager.GetStageStarsMapByChallengeId(challengeId)
    self:Refresh()
    self.CanvasGroup.alpha = 0
    self.GameObject:SetActiveEx(true)
    self.UiRoot:PlayAnimation("StageInfoQieHuan")
end

function XUiPanelStagInfo:Hide()
    self.GameObject:SetActiveEx(false)
end

function XUiPanelStagInfo:Refresh()
    self:SetStartList()
    self:SetDropList()
end

function XUiPanelStagInfo:SetStartList()
    local isNoStart = not self.StageCfg.StarDesc or #self.StageCfg.StarDesc <= 0
    self.PanelStartList.gameObject:SetActiveEx(not isNoStart)
    self.PanelTargetNone.gameObject:SetActiveEx(isNoStart)
    if isNoStart then return end

    for i = 1, MAX_START do
        self.GridStarList[i]:Refresh(self.StageCfg.StarDesc[i], self.StarsMap[i])
    end
end

function XUiPanelStagInfo:SetDropList()
    local stagePass = XDataCenter.ArenaOnlineManager.CheckStagePass(self.ChallengeId)
    self.PanelDropList.gameObject:SetActiveEx(not stagePass)
    self.PanelDorptNone.gameObject:SetActiveEx(stagePass)
    self.TxtOnlineHint.gameObject:SetActiveEx(self.MultiplayerMode)
    local allCount = XDataCenter.ArenaOnlineManager.GetStageTotalCount(self.ChallengeId)
    local curCount = XDataCenter.ArenaOnlineManager.GetStagePassCount(self.ChallengeId)
    self.TxtDorpDesc.text = CS.XTextManager.GetText("ArenaOnlineStageDropDesc", allCount, curCount, allCount)
    if stagePass then return end

    -- 获取显示奖励Id
    local IsFirst = false
    local cfg = XDataCenter.FubenManager.GetStageLevelControl(self.ChallengeId)
    local rewardId = cfg and cfg.FirstRewardShow or self.StageCfg.FirstRewardShow
    if cfg and cfg.FirstRewardShow > 0 or self.StageCfg.FirstRewardShow > 0 then
        IsFirst = true
    end

    if rewardId == 0 then
        rewardId = cfg and cfg.FinishRewardShow or self.StageCfg.FinishRewardShow
    end
    if rewardId == 0 then
        for j = 1, #self.GridList do
            self.GridList[j].GameObject:SetActiveEx(false)
        end
        return
    end

    local rewards = IsFirst and XRewardManager.GetRewardList(rewardId) or XRewardManager.GetRewardListNotCount(rewardId)
    if rewards then
        for i, item in ipairs(rewards) do
            local grid
            if self.GridList[i] then
                grid = self.GridList[i]
            else
                local ui = CS.UnityEngine.Object.Instantiate(self.GridCommon)
                grid = XUiGridCommon.New(self.UiRoot, ui)
                grid.Transform:SetParent(self.PanelDropContent, false)
                self.GridList[i] = grid
            end
            grid:Refresh(item)
            grid.GameObject:SetActiveEx(true)
        end
    end

    local rewardsCount = 0
    if rewards then
        rewardsCount = #rewards
    end

    for j = 1, #self.GridList do
        if j > rewardsCount then
            self.GridList[j].GameObject:SetActiveEx(false)
        end
    end
end

return XUiPanelStagInfo