local XUiGridStageStar = require("XUi/XUiFubenMainLineDetail/XUiGridStageStar")
local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
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
    self.Grid128.gameObject:SetActiveEx(false)
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
end

function XUiFubenExploreDetail:OnEnable()
    self:NewUpdateRewards()
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
        titleName = XFubenShortStoryChapterConfigs.GetStageTitleByStageId(self.StageCfg.StageId)
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
            titleName = XFubenShortStoryChapterConfigs.GetStageTitleByStageId(self.StageCfg.StageId)
            self.TxtFightName.text = string.format("%s-%d %s", titleName, self.StageCfg.OrderId, self.StageCfg.Name)
        elseif self.StageType == XDataCenter.FubenManager.StageType.Mainline then
            chapterOrderId = XDataCenter.FubenMainLineManager.GetChapterOrderIdByStageId(self.StageCfg.StageId)
            self.TxtFightName.text = string.format("%s-%d %s", chapterOrderId, self.StageCfg.OrderId, self.StageCfg.Name)
        else
            self.TxtFightName.text = string.format("%s %s", self.StageCfg.Name, self.StageCfg.Description)
        end

        self.TxtATNums.text = XDataCenter.FubenManager.GetRequireActionPoint(self.StageCfg.StageId)

        if maxChallengeNum > 0 then
            self.TextName.text = CS.XTextManager.GetText("MainLineExploreChallengeCount", maxChallengeNum - chanllengeNum, maxChallengeNum)
        else
            self.TextName.text = ""
        end
    end
    self:PlayAnimation("FightAnimEnable")
end

function XUiFubenExploreDetail:UpdateRewardTitle(isFirstDrop)
    self.TxtDrop.gameObject:SetActiveEx(not isFirstDrop)
    self.TxtFirstDrop.gameObject:SetActiveEx(isFirstDrop)
end

function XUiFubenExploreDetail:NewUpdateRewards()
    local stage = self.StageCfg
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

function XUiFubenExploreDetail:UpdateRewards(rewards, isReceived)
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
    
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(self.StageCfg.StageId)
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
    local beginStoryId = XMVCA.XFuben:GetBeginStoryId(self.StageCfg.StageId)
    if stageInfo.Passed then
        XDataCenter.MovieManager.PlayMovie(beginStoryId, nil, nil, nil, false)
    else
        XDataCenter.FubenManager.FinishStoryRequest(self.StageCfg.StageId, function()
            XDataCenter.MovieManager.PlayMovie(beginStoryId, function()
                if self.Base then
                    self.Base:RefreshForChangeDiff(true)
                end
            end, nil, nil, false)
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