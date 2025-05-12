local XUiGridStageStar = require("XUi/XUiFubenMainLineDetail/XUiGridStageStar")
local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiStageFightControl = require("XUi/XUiCommon/XUiStageFightControl")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiFubenExtraChapterDetail = XLuaUiManager.Register(XLuaUi, "UiFubenMainLineDetailFw")

function XUiFubenExtraChapterDetail:OnAwake()
    self:InitAutoScript()
    self.GridStageStar.gameObject:SetActive(false)
    self.GridCommon.gameObject:SetActive(false)
    self:InitStarPanels()
end

function XUiFubenExtraChapterDetail:OnStart(rootUi)
    self.GridList = {}
    self.RootUi = rootUi
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
end

function XUiFubenExtraChapterDetail:OnEnable()
    -- 动画
    self.IsPlaying = true
    self:PlayAnimation("AnimBegin", handler(self, function()
                self.IsPlaying = false
            end))

    self:AddEventListener()
    self.IsOpen = true

    self:Refresh(self.RootUi.Stage)
end

function XUiFubenExtraChapterDetail:OnDisable()
    self:RemoveEventListener()
    self.IsOpen = false
end

function XUiFubenExtraChapterDetail:InitStarPanels()
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
function XUiFubenExtraChapterDetail:InitAutoScript()
    self:AutoAddListener()
end

function XUiFubenExtraChapterDetail:AutoAddListener()
    self:RegisterClickEvent(self.BtnAddNum, self.OnBtnAddNumClick)
    self:RegisterClickEvent(self.BtnEnter, self.OnBtnEnterClick)
    self:RegisterClickEvent(self.BtnEnterB, self.OnBtnEnterBClick)
    self:RegisterClickEvent(self.BtnAutoFight, self.OnBtnAutoFightClick)
    self:RegisterClickEvent(self.BtnAutoFightComplete, self.OnBtnAutoFightCompleteClick)
end
-- auto
function XUiFubenExtraChapterDetail:OnBtnEnterBClick()
    self:OnBtnEnterClick()
end

function XUiFubenExtraChapterDetail:OnBtnAutoFightClick()
    XDataCenter.AutoFightManager.CheckOpenDialog(self.Stage.StageId, self.Stage)
end

function XUiFubenExtraChapterDetail:OnBtnAutoFightCompleteClick()
    local index = XDataCenter.AutoFightManager.GetIndexByStageId(self.Stage.StageId)
    XDataCenter.AutoFightManager.ObtainRewards(index)
end

function XUiFubenExtraChapterDetail:OnBtnCloseClick()
    self:Hide()
end

function XUiFubenExtraChapterDetail:OnBtnAddNumClick()
    local challengeData = XDataCenter.FubenMainLineManager.GetStageBuyChallengeData(self.Stage.StageId)
    XLuaUiManager.Open("UiBuyAsset", 1, function()
            self:UpdateCommon()
        end, challengeData)
end

function XUiFubenExtraChapterDetail:OnBtnEnterClick()
    if self.IsPlaying then
        return
    end

    if self.Stage == nil then
        XLog.Error("XUiFubenExtraChapterDetail.OnBtnEnterClick: Can not find stage!")
        return
    end

    CsXGameEventManager.Instance:Notify(XEventId.EVENT_FUBEN_ENTERFIGHT, self.Stage)
end

function XUiFubenExtraChapterDetail:Hide()
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

function XUiFubenExtraChapterDetail:Refresh(stage)
    self.Stage = stage or self.Stage
    self:UpdateCommon()
    self:NewUpdateRewards()
    self:UpdateDifficulty()
    self:UpdateStageFightControl()--更新战力限制提示
end

function XUiFubenExtraChapterDetail:UpdateCommon()
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.Stage.StageId)
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(self.Stage.StageId)
    local stageTitle = XDataCenter.ExtraChapterManager.GetChapterDetailsStageTitle(stageInfo.ChapterId)
    self.TxtTitle.text = stageTitle .. "-" .. stageCfg.OrderId .. self.Stage.Name
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

    for i = 1, 3 do
        self.GridStarList[i]:Refresh(self.Stage.StarDesc[i], stageInfo.StarsMap[i])
    end
end

function XUiFubenExtraChapterDetail:UpdateDifficulty()
    local nanDuIcon = XDataCenter.FubenManager.GetDifficultIcon(self.Stage.StageId)
    self.RImgNandu:SetRawImage(nanDuIcon)
end

function XUiFubenExtraChapterDetail:UpdateRewardTitle(isFirstDrop)
    self.TxtDrop.gameObject:SetActiveEx(not isFirstDrop)
    self.TxtFirstDrop.gameObject:SetActiveEx(isFirstDrop)
end

function XUiFubenExtraChapterDetail:NewUpdateRewards()
    local stage = self.Stage
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(stage.StageId)
    local cfg = XDataCenter.FubenManager.GetStageLevelControl(stage.StageId)

    local firstRewardId = cfg and cfg.FirstRewardShow or stage.FirstRewardShow
    local finishRewardId = cfg and cfg.FinishRewardShow or stage.FinishRewardShow

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
        self:UpdateRewards(rewards, stageInfo.Passed)
    end
    -- 只有复刷奖励
    if not firstShow and finishShow then
        firstDrop = false
        local rewards = XRewardManager.GetRewardListNotCount(finishRewardId)
        self:UpdateRewards(rewards, false)
    end
    -- 普通和复刷都有
    if firstShow and finishShow then
        if not stageInfo.Passed then
            firstDrop = true  
        end
        local rewards = not stageInfo.Passed and XRewardManager.GetRewardList(firstRewardId) or XRewardManager.GetRewardListNotCount(finishRewardId)
        self:UpdateRewards(rewards, false)
    end
    self:UpdateRewardTitle(firstDrop)
end

function XUiFubenExtraChapterDetail:UpdateRewards(rewards, isReceived)
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

function XUiFubenExtraChapterDetail:UpdateStageFightControl()
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

function XUiFubenExtraChapterDetail:SetAutoFightActive(value)
    self.PanelAutoFightButton.gameObject:SetActive(value)
    self.BtnEnter.gameObject:SetActive(not value)
end

function XUiFubenExtraChapterDetail:SetAutoFightState(value)
    local state = XDataCenter.AutoFightManager.State
    self.BtnAutoFight.gameObject:SetActive(value == state.None)
    self.ImgAutoFighting.gameObject:SetActive(value == state.Fighting)
    self.BtnAutoFightComplete.gameObject:SetActive(value == state.Complete)
end

function XUiFubenExtraChapterDetail:OnAutoFightStart(stageId)
    if self.Stage.StageId == stageId then
        self.ParentUi:CloseStageDetail()
    end
end

function XUiFubenExtraChapterDetail:OnAutoFightRemove(stageId)
    if self.Stage.StageId == stageId then
        self:SetAutoFightState(XDataCenter.AutoFightManager.State.None)
    end
end

function XUiFubenExtraChapterDetail:OnAutoFightComplete(stageId)
    if self.Stage.StageId == stageId then
        self:SetAutoFightState(XDataCenter.AutoFightManager.State.Complete)
    end
end

function XUiFubenExtraChapterDetail:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_AUTO_FIGHT_START, self.OnAutoFightStart, self)
    XEventManager.AddEventListener(XEventId.EVENT_AUTO_FIGHT_REMOVE, self.OnAutoFightRemove, self)
    XEventManager.AddEventListener(XEventId.EVENT_AUTO_FIGHT_COMPLETE, self.OnAutoFightComplete, self)
end

function XUiFubenExtraChapterDetail:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_AUTO_FIGHT_START, self.OnAutoFightStart, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_AUTO_FIGHT_REMOVE, self.OnAutoFightRemove, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_AUTO_FIGHT_COMPLETE, self.OnAutoFightComplete, self)
end