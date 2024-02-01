--关卡详情
local XUiLivWarmRaceDetail = XLuaUiManager.Register(XLuaUi, "UiLivWarmRaceDetail")

function XUiLivWarmRaceDetail:OnAwake()
    self.Items = {}
    self:InitStarPanels()
    self:AutoAddListener()
end

function XUiLivWarmRaceDetail:OnStart(stageId, closeCb, groupId)
    self.StageId = stageId
    self.CloseCb = closeCb
    self.GroupId = groupId

    local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
    local name = stageCfg.Name
    local dialogIcon = stageCfg.Icon

    if stageCfg.StageType == XFubenConfigs.STAGETYPE_FIGHT or stageCfg.StageType == XFubenConfigs.STAGETYPE_FIGHTEGG or stageCfg.StageType == XFubenConfigs.STAGETYPE_COMMON then
        self.TxtFightName.text = name
        self.RImgFight:SetRawImage(dialogIcon)
        self.PanelStory.gameObject:SetActiveEx(false)
        self.PanelFight.gameObject:SetActiveEx(true)
    else
        self.TxtStoryName.text = name
        self.TxtStoryDec.text = stageCfg.Description
        self.RImgStory:SetRawImage(dialogIcon)
        self.PanelStory.gameObject:SetActiveEx(true)
        self.PanelFight.gameObject:SetActiveEx(false)
    end

    self:UpdateReward(stageId)
    self:UpdateStarPanels(stageId)
    self:UpdateConsumeItem(stageId)
end

function XUiLivWarmRaceDetail:OnDestroy()
    if self.CloseCb then
        self.CloseCb()
    end
end

function XUiLivWarmRaceDetail:InitStarPanels()
    self.GridStarList = {}
    for i = 1, XLivWarmRaceConfigs.MaxStarCount do
        self.GridStarList[i] = XUiGridStageStar.New(self["GridStageStar" .. i])
    end
end

function XUiLivWarmRaceDetail:UpdateConsumeItem(stageId)
    local isStageClear = XDataCenter.LivWarmRaceManager.IsStageClear(stageId)
    if not isStageClear then
        local consumeItemId = XLivWarmRaceConfigs.GetActivityConsumeId()
        local consumeCount = XLivWarmRaceConfigs.GetActivityConsumeCount()
        local icon = XItemConfigs.GetItemIconById(consumeItemId)
        self.Icon:SetRawImage(icon)
        self.Icon.gameObject:SetActiveEx(true)
        self.TxtATNums.text = consumeCount
        self.TextAT.text = CS.XTextManager.GetText("RebootCostText", XDataCenter.ItemManager.GetItemName(consumeItemId))
    else
        self.Icon.gameObject:SetActiveEx(false)
        self.TxtATNums.text = ""
        self.TextAT.text = CS.XTextManager.GetText("LivWarmRaceRepeatChallengeText")
    end
end

function XUiLivWarmRaceDetail:UpdateStarPanels(stageId)
    local starDesc = XFubenConfigs.GetStarDesc(stageId)
    local starMap = XDataCenter.LivWarmRaceManager.GetStarMap(stageId)
    for i = 1, XLivWarmRaceConfigs.MaxStarCount do
        self.GridStarList[i]:Refresh(starDesc[i], starMap[i])
    end
end

function XUiLivWarmRaceDetail:UpdateReward(stageId)
    self.Grid128.gameObject:SetActiveEx(false)

    local rewardId = XFubenConfigs.GetFirstRewardShow(stageId)
    if XTool.IsNumberValid(rewardId) then
        local data = XRewardManager.GetRewardList(rewardId)
        data = XRewardManager.MergeAndSortRewardGoodsList(data)
        XUiHelper.CreateTemplates(self, self.Items, data, XUiGridCommon.New, self.Grid128, self.PanelRewardContent, function(grid, gridData)
            grid:Refresh(gridData)
        end)
        self.PanelReward.gameObject:SetActiveEx(true)
    else
        self.PanelReward.gameObject:SetActiveEx(false)
    end
end

function XUiLivWarmRaceDetail:AutoAddListener()
    self:RegisterClickEvent(self.BtnMask, self.Close)
    self:RegisterClickEvent(self.BtnEnterStory, self.OnBtnEnterStoryClick)
    self:RegisterClickEvent(self.BtnEnterFight, self.OnBtnEnterFightClick)
end

function XUiLivWarmRaceDetail:OnBtnEnterStoryClick()
    local stageId = self.StageId
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
    if stageInfo.Passed then
        XDataCenter.MovieManager.PlayMovie(stageCfg.BeginStoryId)
    else
        XDataCenter.FubenManager.FinishStoryRequest(stageId)
    end
    self:Close()
end

function XUiLivWarmRaceDetail:OnBtnEnterFightClick()
    local data = {
        ["LivWarRaceData"] = {
            ["StageGroupId"] = self.GroupId
        }
    }
    XLuaUiManager.PopThenOpen("UiBattleRoleRoom", self.StageId)
end