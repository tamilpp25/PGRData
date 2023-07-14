local XUiFubenExploreDetail = XLuaUiManager.Register(XLuaUi, "UiFubenExploreDetail")
local StarMaxCount = 3

function XUiFubenExploreDetail:OnStart(base, stageCfg, cb, stageType)
    self.Base = base
    self.StageCfg = stageCfg
    self.CallBack = cb
    self.GridList = {}
    self.StageType = stageType or XDataCenter.FubenManager.StageType.Mainline
    self:SetButtonCallback()

    if stageCfg.StageType == XFubenConfigs.STAGETYPE_STORY or
            stageCfg.StageType == XFubenConfigs.STAGETYPE_STORYEGG then
        self:ShowStoryDialog()
    elseif stageCfg.StageType == XFubenConfigs.STAGETYPE_FIGHT or
            stageCfg.StageType == XFubenConfigs.STAGETYPE_FIGHTEGG or
            stageCfg.StageType == XFubenConfigs.STAGETYPE_COMMON then
        self:ShowFightDialog()
    end

    self:InitStarPanels()
    self:UpdateReward()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
end

function XUiFubenExploreDetail:OnEnable()
    self:UpdateReward()
    self:AddEventListener()
end

function XUiFubenExploreDetail:OnDisable()
    self:RemoveEventListener()
end

function XUiFubenExploreDetail:InitStarPanels()
    self.GridStarList = {}
    self.GridStarObjList = { self.GridStageStar1, self.GridStageStar2, self.GridStageStar3 }
    for i = 1, StarMaxCount do
        local ui = self.GridStarObjList[i]
        ui.gameObject:SetActiveEx(true)
        local grid = XUiGridStageStar.New(ui)
        self.GridStarList[i] = grid
    end
end

function XUiFubenExploreDetail:SetButtonCallback()
    self.BtnMask.CallBack = function()
        self:OnBtnMaskClick()
    end
    self.BtnEnterStory.CallBack = function()
        self:OnBtnEnterStoryClick()
    end
    self.BtnEnterSub.CallBack = function()
        self:OnBtnEnterFightClick()
    end
    self.BtnEnterFight.CallBack = function()
        self:OnBtnEnterFightClick()
    end
    self.BtnMWEnterFight.CallBack = function()
        self:OnBtnEnterFightClick()
    end
    self.BtnAutoFight.CallBack = function()
        self:OnBtnAutoFightClick()
    end
    self.BtnAutoFightComplete.CallBack = function()
        self:OnBtnAutoFightCompleteClick()
    end
end

function XUiFubenExploreDetail:OnBtnMaskClick()
    if self.CallBack then
        self.CallBack()
    end
    self:Close()
end

function XUiFubenExploreDetail:SetAutoFightActive(value)
    self.PanelAutoFightButton.gameObject:SetActive(value)
    self.BtnEnterFight.gameObject:SetActive(not value)
end

function XUiFubenExploreDetail:SetAutoFightState(value)
    local state = XDataCenter.AutoFightManager.State
    self.BtnAutoFight.gameObject:SetActive(value == state.None)
    self.ImgAutoFighting.gameObject:SetActive(value == state.Fighting)
    self.BtnAutoFightComplete.gameObject:SetActive(value == state.Complete)
end

function XUiFubenExploreDetail:ShowStoryDialog()
    local titleName
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(self.StageCfg.StageId)
    if self.StageType == XDataCenter.FubenManager.StageType.ExtraChapter then
        titleName = XDataCenter.ExtraChapterManager.GetChapterDetailsStageTitle(stageInfo.ChapterId)
    elseif self.StageType == XDataCenter.FubenManager.StageType.Mainline then
        titleName = XDataCenter.FubenMainLineManager.GetChapterOrderIdByStageId(self.StageCfg.StageId)
    elseif self.StageType == XDataCenter.FubenManager.StageType.ShortStory then
        titleName = XFubenShortStoryChapterConfigs.GetStageTitleByChapterId(stageInfo.ChapterId)
    end
    self.PanelStory.gameObject:SetActiveEx(true)
    self.PanelFight.gameObject:SetActiveEx(false)
    self.PanelFightMW.gameObject:SetActiveEx(false)

    self.TxtStoryName.text = string.format("%s-%d %s", tostring(titleName), self.StageCfg.OrderId, self.StageCfg.Name)
    self.TxtStoryDec.text = self.StageCfg.Description

    if self.StageCfg.Icon then
        self.RImgStory:SetRawImage(self.StageCfg.Icon)
    end
    self:PlayAnimation("StoryAnimEnable")
end

function XUiFubenExploreDetail:ShowFightDialog()
    if self.Base.IsOnZhouMu then
        self.PanelFight.gameObject:SetActiveEx(false)
        self.PanelStory.gameObject:SetActiveEx(false)
        self.PanelFightMW.gameObject:SetActiveEx(true)

        self.TxtMWFightName.text = self.StageCfg.Name
        self.TxtMWFightDec.text = self.StageCfg.Description
        self.RImgMWFightIcon:SetRawImage(self.StageCfg.Icon)
    else
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(self.StageCfg.StageId)
        local stageData = XDataCenter.FubenManager.GetStageData(self.StageCfg.StageId)
        local maxChallengeNum = XDataCenter.FubenManager.GetStageMaxChallengeNums(self.StageCfg.StageId)
        local chanllengeNum = stageData and stageData.PassTimesToday or 0

        self.PanelNums.gameObject:SetActive(maxChallengeNum > 0)
        self.PanelFight.gameObject:SetActiveEx(true)
        self.PanelStory.gameObject:SetActiveEx(false)
        self.PanelFightMW.gameObject:SetActiveEx(false)

        if self.StageCfg.StoryIcon then
            self.RImgFight:SetRawImage(self.StageCfg.StoryIcon)
        end
        local titleName, chapterOrderId
        if self.StageType == XDataCenter.FubenManager.StageType.ExtraChapter then
            chapterOrderId = XDataCenter.ExtraChapterManager.GetChapterOrderIdByStageId(self.StageCfg.StageId)
            titleName = XDataCenter.ExtraChapterManager.GetChapterDetailsStageTitle(stageInfo.ChapterId)
            self.TxtFightName.text = string.format("%s-%d %s", titleName, self.StageCfg.OrderId, self.StageCfg.Name)
        elseif self.StageType == XDataCenter.FubenManager.StageType.ShortStory then
            titleName = XFubenShortStoryChapterConfigs.GetStageTitleByChapterId(stageInfo.ChapterId)
            self.TxtFightName.text = string.format("%s-%d %s", titleName, self.StageCfg.OrderId, self.StageCfg.Name)
        elseif self.StageType == XDataCenter.FubenManager.StageType.Mainline then
            chapterOrderId = XDataCenter.FubenMainLineManager.GetChapterOrderIdByStageId(self.StageCfg.StageId)
            self.TxtFightName.text = string.format("%s-%d %s", chapterOrderId, self.StageCfg.OrderId, self.StageCfg.Name)
        else
            self.TxtFightName.text = string.format("%s %s", self.StageCfg.Name, self.StageCfg.Description)
        end

        self.TxtATNums.text = self.StageCfg.RequireActionPoint

        if maxChallengeNum > 0 then
            self.TextName.text = CS.XTextManager.GetText("MainLineExploreChallengeCount", maxChallengeNum - chanllengeNum, maxChallengeNum)
        else
            self.TextName.text = ""
        end
    end
    self:PlayAnimation("FightAnimEnable")
end

function XUiFubenExploreDetail:UpdateReward()
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(self.StageCfg.StageId)
    self.Grid128.gameObject:SetActiveEx(false)
    -- 获取显示奖励Id
    local rewardId = 0
    local IsFirst = false
    local HaveReward = true
    local cfg = XDataCenter.FubenManager.GetStageLevelControl(self.StageCfg.StageId)
    if not stageInfo.Passed then
        rewardId = cfg and cfg.FirstRewardShow or self.StageCfg.FirstRewardShow
        if cfg and cfg.FirstRewardShow > 0 or self.StageCfg.FirstRewardShow > 0 then
            IsFirst = true
        end
    end
    if rewardId == 0 then
        rewardId = cfg and cfg.FinishRewardShow or self.StageCfg.FinishRewardShow
    end
    if rewardId == 0 then
        for j = 1, #self.GridList do
            self.GridList[j].GameObject:SetActiveEx(false)
        end
        HaveReward = false
        -- return
    end

    local rewards
    if HaveReward then
        rewards = IsFirst and XRewardManager.GetRewardList(rewardId) or XRewardManager.GetRewardListNotCount(rewardId)
    end
    if rewards then
        for i, item in ipairs(rewards) do
            local grid
            if self.GridList[i] then
                grid = self.GridList[i]
            else
                local ui = CS.UnityEngine.Object.Instantiate(self.Grid128)
                grid = XUiGridCommon.New(self, ui)
                grid.Transform:SetParent(self.PanelRewardContent, false)
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

    self.TxtFirstDrop.gameObject:SetActiveEx(HaveReward and IsFirst)
    self.TxtDrop.gameObject:SetActiveEx(HaveReward and not IsFirst)

    for i = 1, StarMaxCount do
        self.GridStarList[i]:Refresh(self.StageCfg.StarDesc[i], stageInfo.StarsMap[i])
    end

    local showAutoFightBtn = XDataCenter.AutoFightManager.CheckAutoFightAvailable(self.StageCfg.StageId) == XCode.Success
    if showAutoFightBtn then
        self:SetAutoFightState(XDataCenter.AutoFightManager.State.None)
    end
    self:SetAutoFightActive(showAutoFightBtn)
end

function XUiFubenExploreDetail:OnBtnEnterStoryClick()
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(self.StageCfg.StageId)
    self:OnBtnMaskClick()
    if stageInfo.Passed then
        XDataCenter.MovieManager.PlayMovie(self.StageCfg.BeginStoryId)
    else
        XDataCenter.FubenManager.FinishStoryRequest(self.StageCfg.StageId, function()
            XDataCenter.MovieManager.PlayMovie(self.StageCfg.BeginStoryId, function()
                if self.Base then
                    self.Base:RefreshForChangeDiff(true)
                end
            end)
        end)
    end
end

function XUiFubenExploreDetail:OnBtnEnterFightClick()
    if XDataCenter.FubenManager.CheckPreFight(self.StageCfg) then
        self:OnBtnMaskClick()
        XLuaUiManager.Open("UiBattleRoleRoom", self.StageCfg.StageId)
    end
end

function XUiFubenExploreDetail:OnBtnAutoFightClick()
    XDataCenter.AutoFightManager.CheckOpenDialog(self.StageCfg.StageId, self.StageCfg)
end

function XUiFubenExploreDetail:OnBtnAutoFightCompleteClick()
    local index = XDataCenter.AutoFightManager.GetIndexByStageId(self.StageCfg.StageId)
    XDataCenter.AutoFightManager.ObtainRewards(index)
end

function XUiFubenExploreDetail:OnAutoFightStart(stageId)
end

function XUiFubenExploreDetail:OnAutoFightRemove(stageId)
    if self.StageCfg.StageId == stageId then
        self:SetAutoFightState(XDataCenter.AutoFightManager.State.None)
    end
end

function XUiFubenExploreDetail:OnAutoFightComplete(stageId)
    if self.StageCfg.StageId == stageId then
        self:SetAutoFightState(XDataCenter.AutoFightManager.State.Complete)
    end
end

function XUiFubenExploreDetail:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_AUTO_FIGHT_START, self.OnAutoFightStart, self)
    XEventManager.AddEventListener(XEventId.EVENT_AUTO_FIGHT_REMOVE, self.OnAutoFightRemove, self)
    XEventManager.AddEventListener(XEventId.EVENT_AUTO_FIGHT_COMPLETE, self.OnAutoFightComplete, self)
end

function XUiFubenExploreDetail:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_AUTO_FIGHT_START, self.OnAutoFightStart, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_AUTO_FIGHT_REMOVE, self.OnAutoFightRemove, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_AUTO_FIGHT_COMPLETE, self.OnAutoFightComplete, self)
end