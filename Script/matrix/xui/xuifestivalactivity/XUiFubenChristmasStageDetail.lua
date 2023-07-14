local XUiFubenChristmasStageDetail = XLuaUiManager.Register(XLuaUi, "UiFubenChristmasStageDetail")

function XUiFubenChristmasStageDetail:OnAwake()
    self.StarGridList = {}
    self.CommonGridList = {}
    self.GridList = {}

    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint)
    self:InitStarPanels()
    self.BtnEnter.CallBack = function() self:OnBtnEnterClick() end
end

function XUiFubenChristmasStageDetail:InitStarPanels()
    for i = 1, 3 do
        self.StarGridList[i] = XUiGridStageStar.New(self[string.format("GridStageStar%d", i)])
    end
end

function XUiFubenChristmasStageDetail:OnStart(rootUi)
    self.RootUi = rootUi
end

function XUiFubenChristmasStageDetail:SetStageDetail(stageId, festivalId)
    local fStage = XDataCenter.FubenFestivalActivityManager.GetFestivalStageByFestivalIdAndStageId(festivalId, stageId)
    if not fStage then return end
    self.FStage = fStage
    self.FestivalId = festivalId
    local maxChallengeNum = fStage:GetMaxChallengeNum()
    local isLimitCount = maxChallengeNum > 0
    self.PanelNums.gameObject:SetActiveEx(isLimitCount)
    self.PanelNoLimitCount.gameObject:SetActiveEx(not isLimitCount)
    -- 有次数限制
    if isLimitCount then
        self.TxtAllNums.text = string.format("/%d", maxChallengeNum)
        self.TxtLeftNums.text = maxChallengeNum - fStage:GetPassCount()
    end
    self.TxtTitle.text = fStage:GetName()
    for i = 1, 3 do
        self.StarGridList[i]:Refresh(fStage:GetStarDescByIndex(i), fStage:GetStarMapsByIndex(i))
    end
    self.ImgCostIcon:SetRawImage(XDataCenter.ItemManager.GetItemIcon(XDataCenter.ItemManager.ItemId.ActionPoint))
    self.TxtATNums.text = fStage:GetRequireActionPoint()
    self:NewUpdateRewards()
end

function XUiFubenChristmasStageDetail:UpdateRewardTitle(isFirstDrop)
    self.TxtDrop.gameObject:SetActiveEx(not isFirstDrop)
    self.TxtFirstDrop.gameObject:SetActiveEx(isFirstDrop)
end

function XUiFubenChristmasStageDetail:NewUpdateRewards()
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
        self.TxtDrop.gameObject:SetActiveEx(false)
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

function XUiFubenChristmasStageDetail:UpdateRewards(rewards, isReceived)
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

function XUiFubenChristmasStageDetail:OnBtnEnterClick()
    if not self.FStage then
        XLog.Error("XUiFubenChristmasStageDetail:OnBtnEnterClick 函数错误: 关卡信息为空 ")
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
        -- XLuaUiManager.Open("UiNewRoomSingle", self.FStage:GetStageId())
        XLuaUiManager.Open("UiBattleRoleRoom", self.FStage:GetStageId())
        self.RootUi.BtnCloseDetail.gameObject:SetActiveEx(false)
        self.RootUi.PanelStageContentRaycast.raycastTarget = true
        self:Close()
    end
end

function XUiFubenChristmasStageDetail:CloseDetailWithAnimation()
    self:PlayAnimation("AnimDisableEnd", function()
        self:Close()
    end)
end