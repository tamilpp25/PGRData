local XUiGridBabelStageItem = require("XUi/XUiFubenBabelTower/XUiGridBabelStageItem")

local SWITH_BG_TIME = 10 * XScheduleManager.SECOND
local SWITH_BG_INDEX = { 2, 1 }

local XUiBabelTowerMainNew = XLuaUiManager.Register(XLuaUi, "UiBabelTowerMainNew")

function XUiBabelTowerMainNew:OnAwake()
    self:InitIsPlayLoopBgAnimation()
    self:Init()
    XEventManager.AddEventListener(XEventId.EVENT_BABEL_STAGE_INFO_ASYNC, self.RefreshMainUi, self)
    XEventManager.AddEventListener(XEventId.EVENT_BABEL_RESET_STATUES_CHANGED, self.RefreshMainUi, self)
    XEventManager.AddEventListener(XEventId.EVENT_BABEL_ACTIVITY_STATUS_CHANGED, self.OnActivityStatusChanged, self)
end

function XUiBabelTowerMainNew:OnStart()
    self.CurrentActivityNo = XDataCenter.FubenBabelTowerManager.GetCurrentActivityNo()
    self.CurrentActivityMaxScore = XDataCenter.FubenBabelTowerManager.GetCurrentActivityMaxScore()
    self.CurrentActivityTemplate = XFubenBabelTowerConfigs.GetBabelTowerActivityTemplateById(self.CurrentActivityNo)
    if not self.CurrentActivityTemplate then
        return
    end

    self.BtnRank.gameObject:SetActiveEx(self.CurrentActivityTemplate.RankType ~= XFubenBabelTowerConfigs.RankType.NoRank)
    self:RefreshMainUi()

    self.PanelAsset.gameObject:SetActiveEx(true)
    XRedPointManager.AddRedPointEvent(self.RedAchievement, self.RefreshAchievementTaskRedDot, self, { XRedPointConditions.Types.CONDITION_TASK_TYPE }, XDataCenter.TaskManager.TaskType.BabelTower)
    local babelTowerManager = XDataCenter.FubenBabelTowerManager
    local value = babelTowerManager.GetBabelTowerPrefs(XFubenBabelTowerConfigs.HAS_PLAY_BEGINSTORY, 0)
    local activityNo = babelTowerManager.GetCurrentActivityNo()
    local hasPlay = value == 1
    if not hasPlay and activityNo then
        XUiManager.ShowHelpTip("BabelTower")
        XDataCenter.FubenBabelTowerManager.SaveBabelTowerPrefs(XFubenBabelTowerConfigs.HAS_PLAY_BEGINSTORY, 1)
    end
end

function XUiBabelTowerMainNew:OnEnable()
    self:OnActivityStatusChanged()

    self:PlayAnimation("AnimStartEnable", function()
        XLuaUiManager.SetMask(false)
    end, function()
        XLuaUiManager.SetMask(true)
    end)

    self:PlayLoopBgAnimation()
    XRedPointManager.CheckOnce(self.OnCheckTaskRedPoint, self, { XRedPointConditions.Types.CONDITION_ACTIVITYBRIE_BABELTOWER_REWARD })
end

function XUiBabelTowerMainNew:OnDisable()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiBabelTowerMainNew:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_BABEL_STAGE_INFO_ASYNC, self.RefreshMainUi, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_BABEL_RESET_STATUES_CHANGED, self.RefreshMainUi, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_BABEL_ACTIVITY_STATUS_CHANGED, self.OnActivityStatusChanged, self)
end

function XUiBabelTowerMainNew:Init()
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end
    self.BtnAchievement.CallBack = function() self:OnBtnAchievementClick() end
    self:BindHelpBtn(self.BtnHelp, "BabelTower")
    self.BtnRank.CallBack = function() self:OnBtnRankClick() end
    self.BtnRank.gameObject:SetActive(true)

    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
end

function XUiBabelTowerMainNew:InitIsPlayLoopBgAnimation()
    self.IsPlayLoopBgAnimation = true
    for i in ipairs(SWITH_BG_INDEX) do
        self["Bg" .. i].gameObject:SetActiveEx(true)
    end
    local bgObj1 = XUiHelper.TryGetComponent(self.Bg1.transform, "RImgBg", "XLoadRawImage")
    local bgObj2 = XUiHelper.TryGetComponent(self.Bg2.transform, "RImgBg", "XLoadRawImage")
    local bgTexture1 = bgObj1 and bgObj1.AssetUrl
    local bgTexture2 = bgObj2 and bgObj2.AssetUrl
    if bgTexture1 == bgTexture2 then
        self.IsPlayLoopBgAnimation = false
    end
    self.Bg2.gameObject:SetActiveEx(false)
end

function XUiBabelTowerMainNew:OnBeginDrag(eventData)
    self.PanelTaskList:OnBeginDrag(eventData)
    self.IsDraging = true
    self.PreY = self.PanelTaskList.verticalNormalizedPosition
end

function XUiBabelTowerMainNew:OnBtnRankClick()
    XDataCenter.FubenBabelTowerManager.GetRank(function()
        XLuaUiManager.Open("UiFubenBabelTowerRank")
    end)
end

function XUiBabelTowerMainNew:OnBtnBackClick()
    self:Close()
end

function XUiBabelTowerMainNew:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiBabelTowerMainNew:OnBtnAchievementClick()
    -- 时间限制，不在活动期间不给打开
    if not self.CurrentActivityNo or not XDataCenter.FubenBabelTowerManager.IsInActivityTime(self.CurrentActivityNo) then
        XUiManager.TipMsg(CS.XTextManager.GetText("BabelTowerNoneOpen"))
        return
    end

    XLuaUiManager.Open("UiBabelTowerTask")
end

function XUiBabelTowerMainNew:OnActivityStatusChanged()
    if not XLuaUiManager.IsUiShow("UiBabelTowerMainNew") then return end
    local curActivityNo = XDataCenter.FubenBabelTowerManager.GetCurrentActivityNo()
    if not curActivityNo or not XDataCenter.FubenBabelTowerManager.IsInActivityTime(curActivityNo) then
        XUiManager.TipMsg(CS.XTextManager.GetText("BabelTowerNoneOpen"))
        XLuaUiManager.RunMain()
    end
end

function XUiBabelTowerMainNew:CheckPlayBeginStory()
    local value = XDataCenter.FubenBabelTowerManager.GetBabelTowerPrefs(XFubenBabelTowerConfigs.HAS_PLAY_BEGINSTORY, 0)
    local hasPlay = value == 1
    if not hasPlay and self.CurrentActivityNo then
        local storyId = XFubenBabelTowerConfigs.GetActivityBeginStory(self.CurrentActivityNo)
        -- 播放剧情
        if storyId and storyId > 0 then
            XDataCenter.MovieManager.PlayMovie(storyId)
        end
        XDataCenter.FubenBabelTowerManager.SaveBabelTowerPrefs(XFubenBabelTowerConfigs.HAS_PLAY_BEGINSTORY, 1)
    end
end

function XUiBabelTowerMainNew:RefreshAchievementTaskRedDot(count)
    self.RedAchievement.gameObject:SetActive(count >= 0)
end

function XUiBabelTowerMainNew:RefreshMainUi()
    self:UpdateStageDetails()
    self:UpdateStageScores()
end

function XUiBabelTowerMainNew:UpdateStageScores()
    local curScore, maxScore = XDataCenter.FubenBabelTowerManager.GetCurrentActivityScores()
    self.TxtTotalLevel.text = curScore
    self.TxtName.text = XFubenBabelTowerConfigs.GetActivityName(self.CurrentActivityNo)
    self.TxtHighest.text = CS.XTextManager.GetText("BabelTowerCurMaxScore", maxScore)
end

function XUiBabelTowerMainNew:UpdateStageDetails()
    if not self.StageGridChapter then self.StageGridChapter = {} end

    for i = 1, #self.CurrentActivityTemplate.StageId do
        local curStageId = self.CurrentActivityTemplate.StageId[i]
        if not self.StageGridChapter[i] then
            local go = self.PanelStageContent:Find(string.format("Stage%d", i))
            table.insert(self.StageGridChapter, XUiGridBabelStageItem.New(go, self, curStageId))
        end
        self.StageGridChapter[i].GameObject:SetActiveEx(true)
        self.StageGridChapter[i]:UpdateStageInfo(curStageId)
    end

    for i = #self.CurrentActivityTemplate.StageId + 1, #self.StageGridChapter do
        self.StageGridChapter[i].GameObject:SetActiveEx(false)
    end
end

-- 关卡点击
function XUiBabelTowerMainNew:OnStageClick(stageId, grid)

    local isStageUnlock, desc = XDataCenter.FubenBabelTowerManager.IsBabelStageUnlock(stageId)
    if not isStageUnlock then
        XUiManager.TipMsg(desc)
        return
    end

    --  if self.SelectedGrid then
    -- self.SelectedGrid:SetStageItemPress(false)
    -- end
    --self.SelectedGrid = grid
    --  grid:SetStageItemPress(true)
    local stageTemplate = XFubenBabelTowerConfigs.GetBabelTowerStageTemplate(stageId)
    --如果多种难度选择
    if #stageTemplate.StageGuideId > 1 then
        self:PlayScrollViewMove(grid.Transform)
    else
        local currentSelectGuideId = stageTemplate.StageGuideId[1]
        -- 锁住return
        local isUnlock = XDataCenter.FubenBabelTowerManager.IsBabelStageGuideUnlock(stageId, currentSelectGuideId)
        if not isUnlock then
            if not isStageUnlock then
                XUiManager.TipMsg(desc)
            else
                XUiManager.TipMsg(CS.XTextManager.GetText("BabelTowerPassLastGuide"))
            end
            return
        end
        XLuaUiManager.Open("UiBabelTowerSelectTeam", stageId)
    end
end

function XUiBabelTowerMainNew:PlayScrollViewMove(gridTransform)
    self.PanelTaskListScrollRect.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Unrestricted
    local gridRect = gridTransform:GetComponent("RectTransform")
    self.ViewPort.raycastTarget = false
    local diffX = gridRect.localPosition.x + self.PanelStageContent.localPosition.x
    if diffX < XDataCenter.FubenMainLineManager.UiGridChapterMoveMinX or diffX > XDataCenter.FubenMainLineManager.UiGridChapterMoveMaxX then
        local tarPosX = XDataCenter.FubenMainLineManager.UiGridChapterMoveTargetX - gridRect.localPosition.x
        local tarPos = self.PanelStageContent.localPosition
        tarPos.x = tarPosX
        XLuaUiManager.SetMask(true)
        XUiHelper.DoMove(self.PanelStageContent, tarPos, XDataCenter.FubenMainLineManager.UiGridChapterMoveDuration, XUiHelper.EaseType.Sin, function()
            XLuaUiManager.SetMask(false)
        end)
    end
    self.PanelAsset.gameObject:SetActiveEx(false)
end

function XUiBabelTowerMainNew:OnPanelDifficultyClose()
    self.PanelTaskListScrollRect.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic
    self.ViewPort.raycastTarget = true
    if self.CurrentActivityTemplate and self.StageGridChapter then
        for i = 1, #self.CurrentActivityTemplate.StageId do
            if self.StageGridChapter[i] then
                self.StageGridChapter[i]:SetStageItemPress(false)
            end
        end
    end
    self.PanelAsset.gameObject:SetActiveEx(true)
end

function XUiBabelTowerMainNew:PlayLoopBgAnimation()
    if not self.IsPlayLoopBgAnimation then
        return
    end

    local curBgIndex = 1

    self.Timer = self.Timer or XScheduleManager.ScheduleForever(function()
        if XTool.UObjIsNil(self.GameObject) then return end

        self:PlayAnimation("DarkEnable", function()
            self["Bg" .. curBgIndex].gameObject:SetActiveEx(false)
            curBgIndex = SWITH_BG_INDEX[curBgIndex]
            self["Bg" .. curBgIndex].gameObject:SetActiveEx(true)
            self:PlayAnimation("DarkDisable")
        end)
    end, SWITH_BG_TIME)
end

function XUiBabelTowerMainNew:OnCheckTaskRedPoint(count)
    self.BtnAchievement:ShowReddot(count >= 0)
end