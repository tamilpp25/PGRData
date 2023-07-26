local XUiSummerStageDetail = XLuaUiManager.Register(XLuaUi, "UiSummerStageDetail")

function XUiSummerStageDetail:OnAwake()
    self:InitAutoScript()
    self.GridStageStar.gameObject:SetActive(false)
    self.GridCommon.gameObject:SetActive(false)
    self:InitStarPanels()
end

function XUiSummerStageDetail:OnStart(rootUi, stage)
    self.GridList = {}
    self.RootUi = rootUi
    self.Stage = stage
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
end

function XUiSummerStageDetail:OnEnable()
    -- 动画
    self.IsPlaying = true
    self:PlayAnimation("AnimBegin", handler(self, function()
        self.IsPlaying = false
    end))

    self:AddEventListener()
    self.IsOpen = true
    self.Stage = self.RootUi.Stage
    self.Chapter = self.RootUi.CurChapter
    self:Refresh()
end

function XUiSummerStageDetail:OnDisable()
    self:RemoveEventListener()
    self.IsOpen = false
end

function XUiSummerStageDetail:InitStarPanels()
    self.GridStarList = {}
    for i = 1, 3 do
        local ui = self.Transform:Find("SafeAreaContentPane/PanelDetail/PanelTargetList/GridStageStar" .. i)
        ui.gameObject:SetActive(true)
        local grid = XUiGridStageStar.New(ui)
        self.GridStarList[i] = grid
    end
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiSummerStageDetail:InitAutoScript()
    self:AutoAddListener()
end

function XUiSummerStageDetail:AutoAddListener()
    self:RegisterClickEvent(self.BtnAddNum, self.OnBtnAddNumClick)
    self:RegisterClickEvent(self.BtnEnter, self.OnBtnEnterClick)
    self:RegisterClickEvent(self.BtnEnterB, self.OnBtnEnterBClick)
    self:RegisterClickEvent(self.BtnAutoFight, self.OnBtnAutoFightClick)
    self:RegisterClickEvent(self.BtnAutoFightComplete, self.OnBtnAutoFightCompleteClick)
end
-- auto
function XUiSummerStageDetail:OnBtnEnterBClick()
    self:OnBtnEnterClick()
end

function XUiSummerStageDetail:OnBtnAutoFightClick()
    XLuaUiManager.Open("UiAutoFightEnter", self.Stage.StageId, self.Stage)
end

function XUiSummerStageDetail:OnBtnAutoFightCompleteClick()
    local index = XDataCenter.AutoFightManager.GetIndexByStageId(self.Stage.StageId)
    XDataCenter.AutoFightManager.ObtainRewards(index)
end

function XUiSummerStageDetail:OnBtnCloseClick()
    self:Hide()
end

function XUiSummerStageDetail:OnBtnAddNumClick()
    local challengeData = XDataCenter.FubenMainLineManager.GetStageBuyChallengeData(self.Stage.StageId)
    XLuaUiManager.Open("UiBuyAsset", 1, function()
        self:UpdateCommon()
    end, challengeData)
end

function XUiSummerStageDetail:OnBtnEnterClick()

    if XDataCenter.FubenSpecialTrainManager.CheckActivityTimeout(XDataCenter.FubenSpecialTrainManager.CurActiveId, true) then
        return
    end

    if self.IsPlaying then
        return
    end

    if self.Stage == nil then
        XLog.Error("XUiSummerStageDetail.OnBtnEnterClick: Can not find stage!")
        return
    end


    if XDataCenter.FubenManager.OpenRoomSingle(self.Stage) then
        --self:Close()
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_FUBEN_CLOSE_FUBENSTAGEDETAIL)
    end
end

function XUiSummerStageDetail:Hide()
    if self.IsPlaying or not self.IsOpen then
        return
    end

    self.IsPlaying = true
    self:PlayAnimation("AnimEnd", handler(self, function()
        if XTool.UObjIsNil(self.GameObject) then
            return
        end
        self.IsPlaying = false
        self:Close()
    end))
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_FUBEN_CLOSE_FUBENSTAGEDETAIL)
end

function XUiSummerStageDetail:Refresh()
    self:UpdateCommon()
    self:UpdateRewards()
    self:UpdateDifficulty()
    self:UpdateStageFightControl()--更新战力限制提示
end

function XUiSummerStageDetail:UpdateCommon()
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.Stage.StageId)
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(self.Stage.StageId)
    local chapterOrderId = stageCfg.OrderId
    for i, v in ipairs(self.Chapter.StageIds) do
        if v == self.StageId then
            chapterOrderId = i
            break
        end
    end
    self.TxtTitle.text = self.Chapter.PrefixName .. "-" .. tostring(chapterOrderId) .. self.Stage.Name
    self.TxtDesc.text = self.Stage.Description
    self.TxtATNums.text = XDataCenter.FubenManager.GetRequireActionPoint(self.Stage.StageId)

    local maxChallengeNum = XDataCenter.FubenManager.GetStageMaxChallengeNums(self.Stage.StageId)
    local buyChallengeCount = XDataCenter.FubenManager.GetStageBuyChallengeCount(self.Stage.StageId)

    self.PanelNums.gameObject:SetActive(maxChallengeNum > 0)
    self.PanelNoLimitCount.gameObject:SetActive(maxChallengeNum <= 0)
    self.BtnAddNum.gameObject:SetActive(buyChallengeCount > 0)
    local showAutoFightBtn = false
    if stageCfg.AutoFightId > 0 then
        local record = XDataCenter.AutoFightManager.GetRecordByStageId(self.Stage.StageId)
        if record then
            local now = XTime.GetServerNowTimestamp()
            if now >= record.CompleteTime then
                self:SetAutoFightState(XDataCenter.AutoFightManager.State.Complete)
            else
                self:SetAutoFightState(XDataCenter.AutoFightManager.State.Fighting)
            end
            showAutoFightBtn = true
        else
            local autoFightAvailable = XDataCenter.AutoFightManager.CheckAutoFightAvailable(self.Stage.StageId) == XCode.Success
            if autoFightAvailable then
                self:SetAutoFightState(XDataCenter.AutoFightManager.State.None)
                showAutoFightBtn = true
            end
        end
    end
    self:SetAutoFightActive(showAutoFightBtn)

    if maxChallengeNum > 0 then
        local stageData = XDataCenter.FubenManager.GetStageData(self.Stage.StageId)
        local chanllengeNum = stageData and stageData.PassTimesToday or 0
        self.TxtAllNums.text = "/" .. maxChallengeNum
        self.TxtLeftNums.text = maxChallengeNum - chanllengeNum
    end

    local firstDrop = false
    if not stageInfo.Passed then
        local cfg = XDataCenter.FubenManager.GetStageLevelControl(self.Stage.StageId)
        if cfg and cfg.FirstRewardShow > 0 or self.Stage.FirstRewardShow > 0 then
            firstDrop = true
        end
    end
    self.TxtFirstDrop.gameObject:SetActive(firstDrop)
    self.TxtDrop.gameObject:SetActive(not firstDrop)

    for i = 1, 3 do
        self.GridStarList[i]:Refresh(self.Stage.StarDesc[i], stageInfo.StarsMap[i])
    end
end

function XUiSummerStageDetail:UpdateDifficulty()
    local nanDuIcon = XDataCenter.FubenManager.GetDifficultIcon(self.Stage.StageId)
    --赏金任务
    local IsBountyTaskPreFight, task = XDataCenter.BountyTaskManager.CheckBountyTaskPreFight(self.Stage.StageId)
    if IsBountyTaskPreFight then
        local config = XDataCenter.BountyTaskManager.GetBountyTaskConfig(task.Id)
        nanDuIcon = config.StageIcon
    end
    self.RImgNandu:SetRawImage(nanDuIcon)
end

function XUiSummerStageDetail:UpdateRewards()
    local stage = self.Stage
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(stage.StageId)

    -- 获取显示奖励Id
    local rewardId = 0
    local IsFirst = false
    local cfg = XDataCenter.FubenManager.GetStageLevelControl(stage.StageId)
    if not stageInfo.Passed then
        rewardId = cfg and cfg.FirstRewardShow or stage.FirstRewardShow
        if cfg and cfg.FirstRewardShow > 0 or stage.FirstRewardShow > 0 then
            IsFirst = true
        end
    end
    if rewardId == 0 then
        rewardId = cfg and cfg.FinishRewardShow or stage.FinishRewardShow
    end
    if rewardId == 0 then
        for j = 1, #self.GridList do
            self.GridList[j].GameObject:SetActive(false)
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

function XUiSummerStageDetail:UpdateStageFightControl()
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(self.Stage.StageId)
    if self.StageFightControl == nil then
        self.StageFightControl = XUiStageFightControl.New(self.PanelStageFightControl, self.Stage.FightControlId)
    end
    if not stageInfo.Passed and stageInfo.Unlock then
        self.StageFightControl.GameObject:SetActive(true)
        self.StageFightControl:UpdateInfo(self.Stage.FightControlId)
    else
        self.StageFightControl.GameObject:SetActive(false)
    end
end

function XUiSummerStageDetail:SetAutoFightActive(value)
    self.PanelAutoFightButton.gameObject:SetActive(value)
    self.BtnEnter.gameObject:SetActive(not value)
end

function XUiSummerStageDetail:SetAutoFightState(value)
    local state = XDataCenter.AutoFightManager.State
    self.BtnAutoFight.gameObject:SetActive(value == state.None)
    self.ImgAutoFighting.gameObject:SetActive(value == state.Fighting)
    self.BtnAutoFightComplete.gameObject:SetActive(value == state.Complete)
end

function XUiSummerStageDetail:OnAutoFightStart(stageId)
    if self.Stage.StageId == stageId then
        self.ParentUi:CloseStageDetail()
    end
end

function XUiSummerStageDetail:OnAutoFightRemove(stageId)
    if self.Stage.StageId == stageId then
        self:SetAutoFightState(XDataCenter.AutoFightManager.State.None)
    end
end

function XUiSummerStageDetail:OnAutoFightComplete(stageId)
    if self.Stage.StageId == stageId then
        self:SetAutoFightState(XDataCenter.AutoFightManager.State.Complete)
    end
end

function XUiSummerStageDetail:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_AUTO_FIGHT_START, self.OnAutoFightStart, self)
    XEventManager.AddEventListener(XEventId.EVENT_AUTO_FIGHT_REMOVE, self.OnAutoFightRemove, self)
    XEventManager.AddEventListener(XEventId.EVENT_AUTO_FIGHT_COMPLETE, self.OnAutoFightComplete, self)
end

function XUiSummerStageDetail:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_AUTO_FIGHT_START, self.OnAutoFightStart, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_AUTO_FIGHT_REMOVE, self.OnAutoFightRemove, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_AUTO_FIGHT_COMPLETE, self.OnAutoFightComplete, self)
end