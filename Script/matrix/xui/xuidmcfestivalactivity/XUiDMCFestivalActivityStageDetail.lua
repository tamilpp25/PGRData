---@class XUiDMCFestivalActivityStageDetail: XLuaUi
local XUiDMCFestivalActivityStageDetail = XLuaUiManager.Register(XLuaUi, 'UiDMCFestivalActivityStageDetail')
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")

function XUiDMCFestivalActivityStageDetail:OnAwake()
    self.CommonGridList = {}
    self.GridList = {}
    self.GridCommon.gameObject:SetActiveEx(false)
    self.BtnEnter.CallBack = function() self:OnBtnEnterClick() end
end

function XUiDMCFestivalActivityStageDetail:OnStart(rootUi)
    self.RootUi = rootUi
end

function XUiDMCFestivalActivityStageDetail:SetStageDetail(stageId, festivalId)
    self.StageId = stageId
    local fStage = XDataCenter.FubenFestivalActivityManager.GetFestivalStageByFestivalIdAndStageId(festivalId, stageId)
    if not fStage then return end
    self.FStage = fStage
    self.FestivalId = festivalId
    local maxChallengeNum = fStage:GetMaxChallengeNum()
    local isLimitCount = maxChallengeNum > 0
    -- 有次数限制
    if isLimitCount then
        self.TxtAllNums.text = string.format("/%d", maxChallengeNum)
        self.TxtLeftNums.text = maxChallengeNum - fStage:GetPassCount()
    end
    
    ---@type XTableFestivalActivity
    local festivalCfg = XFestivalActivityConfig.GetFestivalById(self.FestivalId)

    local chapter = self.FStage:GetChapter()

    if chapter then
        self.TxtTitleNum.text = string.format("%s%d", chapter:GetStagePrefix(), self.FStage:GetOrderIndex() - 1)
    end
    
    self.TxtTitle.text = fStage:GetName()
    self.TxtDetail.text = fStage:GetStageCfg().Description
    self.RImg:SetRawImage(fStage:GetIcon())
    self:NewUpdateRewards()
    
    -- 入口按钮文本
    if self.FStage:GetStageType() == XFubenConfigs.STAGETYPE_FIGHT or self.FStage:GetStageType() == XFubenConfigs.STAGETYPE_FIGHTEGG or self.FStage:GetStageType() == XFubenConfigs.STAGETYPE_COMMON then
        self.BtnEnter:SetNameByGroup(0, XUiHelper.GetText('DMCFestivalFightStageEnter'))
    elseif self.FStage:GetStageType() == XFubenConfigs.STAGETYPE_STORY or self.FStage:GetStageType() == XFubenConfigs.STAGETYPE_STORYEGG then
        self.BtnEnter:SetNameByGroup(0, XUiHelper.GetText('DMCFestivalStoryStageEnter'))
    end
end

function XUiDMCFestivalActivityStageDetail:UpdateRewardTitle(isFirstDrop)
    --self.TxtDrop.gameObject:SetActiveEx(not isFirstDrop)
    self.TxtFirstDrop.gameObject:SetActiveEx(isFirstDrop)
end

function XUiDMCFestivalActivityStageDetail:NewUpdateRewards()
    if not self.FStage then
        return
    end
    local firstRewardId = self.FStage:GetFirstRewardShow()
    local finishRewardId = self.FStage:GetFinishRewardShow()

    local firstShow = XTool.IsNumberValid(firstRewardId)
    local finishShow = XTool.IsNumberValid(finishRewardId)
    local firstDrop = false
    -- 无奖励
    if not firstShow and not finishShow then
        self.TxtFirstDrop.gameObject:SetActiveEx(false)
        for j = 1, #self.GridList do
            self.GridList[j].GameObject:SetActiveEx(false)
        end
        return
    end
    -- 只有首通奖励
    if firstShow and not finishShow then
        firstDrop = true
        local rewards = XRewardManager.GetRewardList(firstRewardId)
        self:UpdateRewards(rewards, self.FStage:GetIsPass())
    end
    -- 只有复刷奖励
    if not firstShow and finishShow then
        firstDrop = false
        local rewards = XRewardManager.GetRewardListNotCount(finishRewardId)
        self:UpdateRewards(rewards, false)
    end
    -- 普通和复刷都有
    if firstShow and finishShow then
        local passed = self.FStage:GetIsPass()
        if not passed then
            firstDrop = true
        end
        local rewards = not passed and XRewardManager.GetRewardList(firstRewardId) or XRewardManager.GetRewardListNotCount(finishRewardId)
        self:UpdateRewards(rewards, false)
    end
    self:UpdateRewardTitle(firstDrop)
end

function XUiDMCFestivalActivityStageDetail:UpdateRewards(rewards, isReceived)
    if rewards then
        for i, item in ipairs(rewards) do
            local grid
            if self.GridList[i] then
                grid = self.GridList[i]
            else
                local ui = CS.UnityEngine.Object.Instantiate(self.GridCommon)
                grid = XUiGridCommon.New(self, ui)
                grid.Transform:SetParent(self.PanelDropContent, false)
                self.GridList[i] = grid
            end
            grid:Refresh(item)
            grid:SetReceived(isReceived)
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

function XUiDMCFestivalActivityStageDetail:OnBtnEnterClick()
    if self.FStage:GetStageType() == XFubenConfigs.STAGETYPE_FIGHT or self.FStage:GetStageType() == XFubenConfigs.STAGETYPE_FIGHTEGG or self.FStage:GetStageType() == XFubenConfigs.STAGETYPE_COMMON then
        self:EnterFightStage()
    elseif self.FStage:GetStageType() == XFubenConfigs.STAGETYPE_STORY or self.FStage:GetStageType() == XFubenConfigs.STAGETYPE_STORYEGG then
        self:EnterStoryStage()    
    end
end

function XUiDMCFestivalActivityStageDetail:EnterFightStage()
    if not self.FStage then
        XLog.Error("XUiDMCFestivalActivityStageDetail:OnBtnEnterClick 函数错误: 关卡信息为空 ")
        return
    end
    local isInTime, tips = self.FStage:GetChapter():GetIsInTimeAndTips()
    if not isInTime then
        XUiManager.TipMsg(tips)
        return
    end
    local passedCounts = self.FStage:GetPassCount()
    local maxChallengeNum = self.FStage:GetMaxChallengeNum()
    if maxChallengeNum > 0 and passedCounts >= maxChallengeNum then
        XUiManager.TipMsg(CS.XTextManager.GetText("FubenChallengeCountNotEnough"))
        return
    end
    if XDataCenter.FubenManager.CheckPreFight(self.FStage:GetStageCfg()) then
        if self.RootUi then
            self.RootUi:ClearNodesSelect()
        end
        XLuaUiManager.Open("UiBattleRoleRoom", self.FStage:GetStageId())
        self.RootUi.BtnCloseDetail.gameObject:SetActiveEx(false)
        self.RootUi.PanelStageContentRaycast.raycastTarget = true
        self:Close()
    end
end

function XUiDMCFestivalActivityStageDetail:EnterStoryStage()
    if not self.StageId then return end

    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.StageId)
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(self.StageId)
    if not stageCfg or not stageInfo then return end

    local beginStoryId = XMVCA.XFuben:GetBeginStoryId(self.StageId)
    if stageInfo.Passed then
        self:PlayStoryId(beginStoryId, self.StageId)
    else
        XDataCenter.FubenFestivalActivityManager.FinishStoryRequest(self.StageId, function()
            XDataCenter.FubenFestivalActivityManager.RefreshStagePassedBySettleDatas({ StageId = self.StageId })
            self:PlayStoryId(beginStoryId, self.StageId)
        end)
    end
end

function XUiDMCFestivalActivityStageDetail:PlayStoryId(movieId)
    XDataCenter.MovieManager.PlayMovie(movieId, function()
        self.RootUi:EndScrollViewMove()
    end)
end

function XUiDMCFestivalActivityStageDetail:CloseDetailWithAnimation()
    self:PlayAnimation("AnimDisableEnd", function()
        self:Close()
    end)
end

return XUiDMCFestivalActivityStageDetail