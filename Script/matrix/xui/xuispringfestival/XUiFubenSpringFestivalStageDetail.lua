local XUiGridStageStar = require("XUi/XUiFubenMainLineDetail/XUiGridStageStar")
local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiFubenSpringFestivalStageDetail = XLuaUiManager.Register(XLuaUi, "UiFubenSpringFestivalStageDetail")

function XUiFubenSpringFestivalStageDetail:OnAwake()
    self.StarGridList = {}
    self.CommonGridList = {}
    self.GridList = {}

    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint)
    self:InitStarPanels()
    self.BtnEnter.CallBack = function() self:OnBtnEnterClick() end
end

function XUiFubenSpringFestivalStageDetail:InitStarPanels()
    for i = 1, 3 do
        self.StarGridList[i] = XUiGridStageStar.New(self[string.format("GridStageStar%d", i)])
    end
end

function XUiFubenSpringFestivalStageDetail:OnStart(rootUi)
    self.RootUi = rootUi
end

function XUiFubenSpringFestivalStageDetail:SetStageDetail(stageId, festivalId)
    local fStage = XDataCenter.FubenFestivalActivityManager.GetFestivalStageByFestivalIdAndStageId(festivalId, stageId)
    if not fStage then return end
    self.FStage = fStage
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
    self:UpdateRewards()
end

function XUiFubenSpringFestivalStageDetail:UpdateRewardTitle(isFirstDrop)
    self.TxtDrop.gameObject:SetActive(not isFirstDrop)
    self.TxtFirstDrop.gameObject:SetActive(isFirstDrop)
end

function XUiFubenSpringFestivalStageDetail:UpdateRewards()
    if not self.FStage then return end
    local rewardId = self.FStage:GetFinishRewardShow()
    local IsFirst = false
    -- 首通有没有填
    local controlCfg = XDataCenter.FubenManager.GetStageLevelControl(self.FStage:GetStageId())
    -- 有首通
    if not self.FStage:GetIsPass() then
        if controlCfg and controlCfg.FirstRewardShow > 0 then
            rewardId = controlCfg.FirstRewardShow
            IsFirst = true
        elseif self.FStage:GetFirstRewardShow() > 0 then
            rewardId = self.FStage:GetFirstRewardShow()
            IsFirst = true
        end
    end
    -- 没首通
    if not IsFirst then
        if controlCfg and controlCfg.FinishRewardShow > 0 then
            rewardId = controlCfg.FinishRewardShow
        else
            rewardId = self.FStage:GetFinishRewardShow()
        end
    end
    self:UpdateRewardTitle(IsFirst)

    local rewards = {}
    if rewardId > 0 then
        rewards = IsFirst and XRewardManager.GetRewardList(rewardId) or XRewardManager.GetRewardListNotCount(rewardId)
    end

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
            grid.GameObject:SetActive(true)
        end
    end

    local rewardsCount = 0
    if rewards then
        rewardsCount = #rewards
    end

    for j = 1, #self.GridList do
        if j > rewardsCount then
            self.GridList[j].GameObject:SetActive(false)
        end
    end
end

function XUiFubenSpringFestivalStageDetail:OnBtnEnterClick()
    if not self.FStage then
        XLog.Error("XUiFubenSpringFestivalStageDetail:OnBtnEnterClick 函数错误: 关卡信息为空 ")
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
            self.RootUi:CloseStageDetails()
        end
        XLuaUiManager.Open("UiBattleRoleRoom", self.FStage:GetStageId())
    end
end

function XUiFubenSpringFestivalStageDetail:CloseDetailWithAnimation()
    self:PlayAnimation("AnimDisableEnd", function()
        self:Close()
    end)
end