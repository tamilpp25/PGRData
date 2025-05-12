local XUiGridStageStar = require("XUi/XUiFubenMainLineDetail/XUiGridStageStar")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiMultiDimSingleCopyTips = XLuaUiManager.Register(XLuaUi, "UiMultiDimSingleCopyTips")
-- 此类和大部分关卡detail类似，命名是ui定的
function XUiMultiDimSingleCopyTips:OnAwake()
    self.StarGridList = {}
    self.GridList = {}

    local itemId = XDataCenter.MultiDimManager.GetActivityItemId()
    self.AssetPanel = XUiHelper.NewPanelActivityAssetSafe({ itemId }, self.PanelSpecialTool, self)
    self:InitStarPanels()
    self.BtnEnter.CallBack = function() self:OnBtnEnterClick() end
    self.BtnRewardTip.CallBack = function() self:OnBtnRewardTipClick() end
    self.BtnDetailInfo.CallBack = function() self:OnBtnDetailInfoClick() end
end

function XUiMultiDimSingleCopyTips:InitStarPanels()
    for i = 1, 3 do
        self.StarGridList[i] = XUiGridStageStar.New(self[string.format("GridStageStar%d", i)])
    end
end

function XUiMultiDimSingleCopyTips:OnStart(rootUi)
    self.RootUi = rootUi
end

--mStage:表MultiDimSingleFuben
function XUiMultiDimSingleCopyTips:SetStageDetail(stageId, festivalId)
    local mStage = XMultiDimConfig.GetMultiSingleStageDataById(stageId)
    if not mStage then return end
    self.MStage = mStage
    self.StageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
    self.StageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)

    -- 屏蔽挑战次数
    -- local maxChallengeNum = XDataCenter.FubenManager.GetStageMaxChallengeNums(stageId)
    -- local isLimitCount = maxChallengeNum > 0
    -- self.PanelNums.gameObject:SetActiveEx(isLimitCount)
    -- self.PanelNoLimitCount.gameObject:SetActiveEx(not isLimitCount)
    self.PanelNums.gameObject:SetActiveEx(false)
    self.PanelNoLimitCount.gameObject:SetActiveEx(false)
    -- -- 有次数限制
    -- if isLimitCount then
    --     self.TxtAllNums.text = string.format("/%d", maxChallengeNum)
    --     local stageData = XDataCenter.FubenManager.GetStageData(self.StageCfg.StageId)
    --     local passedCounts = stageData and stageData.PassTimesToday or 0
    --     self.TxtLeftNums.text = maxChallengeNum - passedCounts
    -- end

    self.TxtTitle.text = self.StageCfg.Name
    for i = 1, 3 do
        self.StarGridList[i]:Refresh(self.StageCfg.StarDesc[i], self.StageInfo.StarsMap[i])
    end

    -- 若没到开启时间则提示
    self.IsLock = not XFunctionManager.CheckInTimeByTimeId(self.MStage.OpenTimeId)
    if self.IsLock then
        self.BtnEnter:SetDisable(true)
        self.TextTime.gameObject:SetActive(true)

        local startTime = XFunctionManager.GetStartTimeByTimeId(self.MStage.OpenTimeId)
        local dayFormat = CS.XTextManager.GetText("TimeFormatMinute")
        local startTimeStr = XTime.TimestampToGameDateTimeString(startTime, dayFormat)
        startTimeStr = XUiHelper.GetText("MultiDimSingleStageOpenText", startTimeStr)
        self.TextTime.text = startTimeStr
    else
        self.BtnEnter:SetDisable(false)
        self.BtnEnter.gameObject:SetActive(true)
        self.TextTime.gameObject:SetActive(false)
    end 

    --进入消耗道具
    -- self.ImgCostIcon:SetRawImage(XDataCenter.ItemManager.GetItemIcon(XDataCenter.ItemManager.ItemId.ActionPoint))
    -- self.TxtATNums.text = mStage:GetRequireActionPoint()
    self:UpdateRewards()
end

function XUiMultiDimSingleCopyTips:UpdateRewardTitle(isFirstDrop)
    self.TxtDrop.gameObject:SetActive(not isFirstDrop)
    self.TxtFirstDrop.gameObject:SetActive(isFirstDrop)
end

function XUiMultiDimSingleCopyTips:UpdateRewards()
    if not self.MStage then return end
    local rewardId = self.StageCfg.FinishRewardShow
    local IsFirst = false
    -- 首通有没有填
    local controlCfg = XDataCenter.FubenManager.GetStageLevelControl(self.StageCfg.StageId)
    -- 有首通
    if not self.StageInfo.Passed then
        if controlCfg and controlCfg.FirstRewardShow > 0 then
            rewardId = controlCfg.FirstRewardShow
            IsFirst = true
        elseif self.StageCfg.FirstRewardShow > 0 then
            rewardId = self.StageCfg.FirstRewardShow
            IsFirst = true
        end
    end
    -- 没首通
    if not IsFirst then
        if controlCfg and controlCfg.FinishRewardShow > 0 then
            rewardId = controlCfg.FinishRewardShow
        else
            rewardId = self.StageCfg.FinishRewardShow
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
    self.GridCommon.gameObject:SetActive(false)

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

function XUiMultiDimSingleCopyTips:OnBtnEnterClick()
    if not self.MStage then
        XLog.Error("XUiMultiDimSingleCopyTips:OnBtnEnterClick 函数错误: 关卡信息为空 ")
        return
    end
    -- local isInTime, tips = self.MStage:GetChapter():GetIsInTimeAndTips()
    -- if not isInTime then
    --     XUiManager.TipMsg(tips)
    --     return
    -- end

    -- 屏蔽挑战次数
    -- local stageData = XDataCenter.FubenManager.GetStageData(self.StageCfg.StageId)
    -- local passedCounts = stageData and stageData.PassTimesToday or 0
    -- local maxChallengeNum = XDataCenter.FubenManager.GetStageMaxChallengeNums(self.StageCfg.StageId)
    -- if maxChallengeNum > 0 and passedCounts >= maxChallengeNum then
    --     XUiManager.TipMsg(CS.XTextManager.GetText("FubenChallengeCountNotEnough"))
    --     return
    -- end

    if XDataCenter.FubenManager.CheckPreFight(self.StageCfg) then
        if self.RootUi then
            self.RootUi:ClearNodesSelect()
        end
        XLuaUiManager.Open("UiBattleRoleRoom",
        self.StageCfg.StageId,
        XDataCenter.TeamManager.GetXTeamByTypeId(CS.XGame.Config:GetInt("TypeIdMultiDimSingle")),
        require("XUi/XUiMultiDim/XUiMultiDimSingleCopyRoleRoom"))

        self.RootUi:CloseStageDetails()
        self:Close()
    end
end

function XUiMultiDimSingleCopyTips:OnBtnRewardTipClick()
    XLuaUiManager.Open("UiMultiDimRewardTips", self.MStage)
end

-- 挑战详情
function XUiMultiDimSingleCopyTips:OnBtnDetailInfoClick()
    XLuaUiManager.Open("UiMultiDimDetails", self.MStage.StageId, true)
end

function XUiMultiDimSingleCopyTips:CloseDetailWithAnimation()
    -- self:PlayAnimation("AnimDisableEnd", function()
    self:Close()
    -- end)
end