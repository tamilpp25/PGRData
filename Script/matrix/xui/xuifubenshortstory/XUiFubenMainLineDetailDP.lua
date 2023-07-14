local XUiFubenMainLineDetailDP = XLuaUiManager.Register(XLuaUi,"UiFubenMainLineDetailDP")

function XUiFubenMainLineDetailDP:OnAwake()
    self:InitAutoScript()
    self.GridStageStar.gameObject:SetActiveEx(false)
    self.GridCommon.gameObject:SetActiveEx(false)
    self:InitStarPanels()
end

function XUiFubenMainLineDetailDP:OnStart(rootUi, enterStoryCb)
    self.GridList = {}
    self.RootUi = rootUi
    self.EnterStoryCb = enterStoryCb
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
end

function XUiFubenMainLineDetailDP:OnEnable()
    -- 动画
    self.IsPlaying = true
    self:PlayAnimation("AnimBegin", handler(self, function()
        self.IsPlaying = false
    end))

    self:AddEventListener()
    self.IsOpen = true

    self:Refresh(self.RootUi.Stage)
end

function XUiFubenMainLineDetailDP:OnDisable()
    self:RemoveEventListener()
    self.IsOpen = false
end

function XUiFubenMainLineDetailDP:InitStarPanels()
    self.GridStarList = {}
    for i = 1, 3 do
        local ui = self.Transform:Find("SafeAreaContentPane/PanelDetail/PanelTargetList/GridStageStar" .. i)
        ui.gameObject:SetActiveEx(true)
        local grid = XUiGridStageStar.New(ui)
        self.GridStarList[i] = grid
    end
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiFubenMainLineDetailDP:InitAutoScript()
    self:AutoAddListener()
end

function XUiFubenMainLineDetailDP:AutoAddListener()
    self:RegisterClickEvent(self.BtnAddNum, self.OnBtnAddNumClick)
    self:RegisterClickEvent(self.BtnEnter, self.OnBtnEnterClick)
    self:RegisterClickEvent(self.BtnEnterB, self.OnBtnEnterBClick)
    self:RegisterClickEvent(self.BtnAutoFight, self.OnBtnAutoFightClick)
    self:RegisterClickEvent(self.BtnAutoFightComplete, self.OnBtnAutoFightCompleteClick)
end
-- auto
function XUiFubenMainLineDetailDP:OnBtnEnterBClick()
    self:OnBtnEnterClick()
end

function XUiFubenMainLineDetailDP:OnBtnAutoFightClick()
    XDataCenter.AutoFightManager.CheckOpenDialog(self.Stage.StageId, self.Stage)
end

function XUiFubenMainLineDetailDP:OnBtnAutoFightCompleteClick()
    local index = XDataCenter.AutoFightManager.GetIndexByStageId(self.Stage.StageId)
    XDataCenter.AutoFightManager.ObtainRewards(index)
end

function XUiFubenMainLineDetailDP:OnBtnCloseClick()
    self:Hide()
end

function XUiFubenMainLineDetailDP:OnBtnAddNumClick()
    local challengeData = XDataCenter.FubenMainLineManager.GetStageBuyChallengeData(self.Stage.StageId)
    XLuaUiManager.Open("UiBuyAsset", 1, function()
        self:UpdateCommon()
    end, challengeData)
end

function XUiFubenMainLineDetailDP:OnBtnEnterClick()
    if self.IsPlaying then
        return
    end

    if self.Stage == nil then
        XLog.Error("XUiFubenMainLineDetailDP.OnBtnEnterClick: Can not find stage!")
        return
    end
    
    if self.EnterStoryCb then
        self.EnterStoryCb(self.Stage)
    end
end

function XUiFubenMainLineDetailDP:Hide()
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

function XUiFubenMainLineDetailDP:Refresh(stage)
    self.Stage = stage or self.Stage
    self:UpdateCommon()
    self:UpdateRewards()
    self:UpdateDifficulty()
    self:UpdateStageFightControl()--更新战力限制提示
end

function XUiFubenMainLineDetailDP:UpdateCommon()
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.Stage.StageId)
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(self.Stage.StageId)
    local stageTitle = XFubenShortStoryChapterConfigs.GetStageTitleByChapterId(stageInfo.ChapterId)
    self.TxtTitle.text = stageTitle .. "-" .. stageCfg.OrderId .. " " .. self.Stage.Name
    self.TxtDesc.text = self.Stage.Description
    self.TxtATNums.text = self.Stage.RequireActionPoint

    local maxChallengeNum = XDataCenter.FubenManager.GetStageMaxChallengeNums(self.Stage.StageId)
    local buyChallengeCount = XDataCenter.FubenManager.GetStageBuyChallengeCount(self.Stage.StageId)

    self.PanelNums.gameObject:SetActiveEx(maxChallengeNum > 0)
    self.PanelNoLimitCount.gameObject:SetActiveEx(maxChallengeNum <= 0)
    self.BtnAddNum.gameObject:SetActiveEx(buyChallengeCount > 0)
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
    self.TxtFirstDrop.gameObject:SetActiveEx(firstDrop)
    self.TxtDrop.gameObject:SetActiveEx(not firstDrop)

    for i = 1, 3 do
        self.GridStarList[i]:Refresh(self.Stage.StarDesc[i], stageInfo.StarsMap[i])
    end
end

function XUiFubenMainLineDetailDP:UpdateDifficulty()
    local nanDuIcon = XDataCenter.FubenManager.GetDifficultIcon(self.Stage.StageId)
    self.RImgNandu:SetRawImage(nanDuIcon)
end

function XUiFubenMainLineDetailDP:UpdateRewards()
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
                grid = XUiGridCommon.New(self, ui)
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

function XUiFubenMainLineDetailDP:UpdateStageFightControl()
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(self.Stage.StageId)
    if self.StageFightControl == nil then
        self.StageFightControl = XUiStageFightControl.New(self.PanelStageFightControl, self.Stage.FightControlId)
    end
    if not stageInfo.Passed and stageInfo.Unlock then
        self.StageFightControl.GameObject:SetActiveEx(true)
        self.StageFightControl:UpdateInfo(self.Stage.FightControlId)
    else
        self.StageFightControl.GameObject:SetActiveEx(false)
    end
end

function XUiFubenMainLineDetailDP:SetAutoFightActive(value)
    self.PanelAutoFightButton.gameObject:SetActiveEx(value)
    self.BtnEnter.gameObject:SetActiveEx(not value)
end

function XUiFubenMainLineDetailDP:SetAutoFightState(value)
    local state = XDataCenter.AutoFightManager.State
    self.BtnAutoFight.gameObject:SetActiveEx(value == state.None)
    self.ImgAutoFighting.gameObject:SetActiveEx(value == state.Fighting)
    self.BtnAutoFightComplete.gameObject:SetActiveEx(value == state.Complete)
end

function XUiFubenMainLineDetailDP:OnAutoFightStart(stageId)
    if self.Stage.StageId == stageId then
        self.ParentUi:CloseStageDetail()
    end
end

function XUiFubenMainLineDetailDP:OnAutoFightRemove(stageId)
    if self.Stage.StageId == stageId then
        self:SetAutoFightState(XDataCenter.AutoFightManager.State.None)
    end
end

function XUiFubenMainLineDetailDP:OnAutoFightComplete(stageId)
    if self.Stage.StageId == stageId then
        self:SetAutoFightState(XDataCenter.AutoFightManager.State.Complete)
    end
end

function XUiFubenMainLineDetailDP:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_AUTO_FIGHT_START, self.OnAutoFightStart, self)
    XEventManager.AddEventListener(XEventId.EVENT_AUTO_FIGHT_REMOVE, self.OnAutoFightRemove, self)
    XEventManager.AddEventListener(XEventId.EVENT_AUTO_FIGHT_COMPLETE, self.OnAutoFightComplete, self)
end

function XUiFubenMainLineDetailDP:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_AUTO_FIGHT_START, self.OnAutoFightStart, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_AUTO_FIGHT_REMOVE, self.OnAutoFightRemove, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_AUTO_FIGHT_COMPLETE, self.OnAutoFightComplete, self)
end

return XUiFubenMainLineDetailDP