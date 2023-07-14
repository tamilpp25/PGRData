local CsXTextManagerGetText = CS.XTextManager.GetText

local XUiFubenRepeatChallengeStageDetail = XLuaUiManager.Register(XLuaUi, "UiFubenRepeatChallengeStageDetail")

function XUiFubenRepeatChallengeStageDetail:OnAwake()
    self:InitAutoScript()
    self.GridCommon.gameObject:SetActiveEx(false)
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
end

function XUiFubenRepeatChallengeStageDetail:OnStart(parent)
    self.GridList = {}
    self.Parent = parent
end

function XUiFubenRepeatChallengeStageDetail:OnEnable()
    self.Parent.PanelAsset.gameObject:SetActiveEx(false)
end

function XUiFubenRepeatChallengeStageDetail:OnDisable()
    self.Parent.PanelAsset.gameObject:SetActiveEx(true)
end

function XUiFubenRepeatChallengeStageDetail:Refresh(stage)
    self.Stage = stage

    if stage.StageType == XFubenConfigs.STAGETYPE_STORY or stage.StageType == XFubenConfigs.STAGETYPE_STORYEGG then
        self:UpdateStory()
    else
        self:UpdateCommon()
        self:UpdateRewards()
    end
end

function XUiFubenRepeatChallengeStageDetail:UpdateStory()
    local stageId = self.Stage.StageId
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)

    self.TxtTitleStory.text = stageCfg.Name
    self.TxtStoryDes.text = stageCfg.Description

    self.PanelFight.gameObject:SetActiveEx(false)
    self.PanelStory.gameObject:SetActiveEx(true)
end

function XUiFubenRepeatChallengeStageDetail:UpdateCommon()
    local stageId = self.Stage.StageId
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
    local nanDuIcon = XDataCenter.FubenManager.GetDifficultIcon(stageId)
    local maxChallengeNum = XDataCenter.FubenManager.GetStageMaxChallengeNums(stageId)
    local buyChallengeCount = XDataCenter.FubenManager.GetStageBuyChallengeCount(stageId)

    self.RImgNandu:SetRawImage(nanDuIcon)
    self.TxtTitle.text = self.Stage.Name
    self.TxtLevelVal.text = self.Stage.RecommandLevel
    self.TxtATNums.text = self.Stage.RequireActionPoint
    self.PanelNums.gameObject:SetActiveEx(maxChallengeNum > 0)
    self.PanelNoLimitCount.gameObject:SetActiveEx(maxChallengeNum <= 0)
    self.BtnAddNum.gameObject:SetActiveEx(buyChallengeCount > 0)
    for i = 1, 3 do
        self["TxtActive" .. i].text = stageCfg.StarDesc[i]
    end

    if maxChallengeNum > 0 then
        local stageData = XDataCenter.FubenManager.GetStageData(stageId)
        local chanllengeNum = stageData and stageData.PassTimesToday or 0
        self.TxtAllNums.text = "/" .. maxChallengeNum
        self.TxtLeftNums.text = maxChallengeNum - chanllengeNum
    end


    local firstDrop = false
    local cfg = XDataCenter.FubenManager.GetStageLevelControl(stageId)
    if cfg and cfg.FirstRewardShow > 0 or self.Stage.FirstRewardShow > 0 then
        firstDrop = true
    end
    self.TxtFirstDrop.gameObject:SetActiveEx(firstDrop)
    self.TxtDrop.gameObject:SetActiveEx(not firstDrop)

    local firstPass = firstDrop and not stageInfo.Passed
    self.BtnFirstEnter.gameObject:SetActiveEx(firstPass)
    self.BtnEnter.gameObject:SetActiveEx(not firstPass)

    self.BtnAutoFight.gameObject:SetActiveEx(XDataCenter.FubenRepeatChallengeManager.IsAutoFightOpen())
    self.BtnAutoFight:SetDisable(not XDataCenter.FubenRepeatChallengeManager.IsStageCanAutoFight(stageId))

    local exConsumeId, exConsumeNum = XDataCenter.FubenManager.GetStageExCost(stageId)
    if exConsumeId ~= 0 and exConsumeNum ~= 0 then
        self.RawImgCostIcon:SetRawImage(XDataCenter.ItemManager.GetItemIcon(exConsumeId))
        self.TxtCostNum.text = exConsumeNum
        self.PanelCostEx.gameObject:SetActiveEx(true)
    else
        self.PanelCostEx.gameObject:SetActiveEx(false)
    end

    self.PanelFight.gameObject:SetActiveEx(true)
    self.PanelStory.gameObject:SetActiveEx(false)
end

function XUiFubenRepeatChallengeStageDetail:UpdateRewards()
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

-- auto
-- Automatic generation of code, forbid to edit
function XUiFubenRepeatChallengeStageDetail:InitAutoScript()
    self:AutoAddListener()
end

function XUiFubenRepeatChallengeStageDetail:AutoAddListener()
    self:RegisterClickEvent(self.BtnAddNum, self.OnBtnAddNumClick)
    self:RegisterClickEvent(self.BtnFirstEnter, self.OnBtnFirstEnterClick)
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.BtnEnter, self.OnBtnEnterClick)
    self:RegisterClickEvent(self.BtnAutoFight, self.OnBtnAutoFight)
    self:RegisterClickEvent(self.BtnEnterStory, self.OnBtnEnterStoryClick)
end

function XUiFubenRepeatChallengeStageDetail:OnBtnCloseClick()
    self:CloseWithAnimDisable()
end
-- auto
function XUiFubenRepeatChallengeStageDetail:OnBtnAddNumClick()
    local challengeData = XDataCenter.FubenMainLineManager.GetStageBuyChallengeData(self.Stage.StageId)
    XLuaUiManager.Open("UiBuyAsset", 1, function()
        self:UpdateCommon()
    end, challengeData)
end

function XUiFubenRepeatChallengeStageDetail:OnBtnFirstEnterClick()
    local chapterId = self.Parent.SelectChapterId
    local isFinished = XDataCenter.FubenRepeatChallengeManager.IsChapterFinished(chapterId)
    if isFinished then
        XUiManager.TipError(CsXTextManagerGetText("ActivityRepeatChallengeChapterFinished"))
        return
    end

    if XDataCenter.FubenManager.CheckPreFight(self.Stage) then
        self.Parent:CloseStageDetail()
        XLuaUiManager.Open("UiNewRoomSingle", self.Stage.StageId)
    end
end

function XUiFubenRepeatChallengeStageDetail:OnBtnEnterClick()
    local chapterId = self.Parent.SelectChapterId
    local isFinished = XDataCenter.FubenRepeatChallengeManager.IsChapterFinished(chapterId)
    if isFinished then
        XUiManager.TipError(CsXTextManagerGetText("ActivityRepeatChallengeChapterFinished"))
        return
    end

    self.Parent:CloseStageDetail()
    XLuaUiManager.Open("UiRepeatChallengeEnter", self.Stage)
end

function XUiFubenRepeatChallengeStageDetail:OnBtnAutoFight()
    if XDataCenter.FubenRepeatChallengeManager.IsStageCanAutoFight(self.Stage.StageId) then 
        XDataCenter.AutoFightManager.CheckOpenDialog(self.Stage.StageId, self.Stage)
    else
        XUiManager.TipErrorWithKey("FubenRepeatChallengeAutoFightOpenTip")
    end
end

function XUiFubenRepeatChallengeStageDetail:OnBtnEnterStoryClick()
    local stageId = self.Stage.StageId
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
    if not stageCfg or not stageInfo then return end

    if stageInfo.Passed then
        XDataCenter.MovieManager.PlayMovie(stageCfg.BeginStoryId)
    else
        XDataCenter.FubenManager.FinishStoryRequest(stageId, function()
            XDataCenter.MovieManager.PlayMovie(stageCfg.BeginStoryId, function()
                XDataCenter.FubenRepeatChallengeManager.PassStage(stageId)
                if self.Parent then
                    self.Parent:RefreshChapterList()
                end
            end)
        end)
    end
end

function XUiFubenRepeatChallengeStageDetail:CloseWithAnimDisable()
    self:PlayAnimation("AnimEnd", function()
        self:Close()
    end)
end