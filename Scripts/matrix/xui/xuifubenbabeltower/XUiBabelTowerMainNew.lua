local XUiGridBabelStageItem = require("XUi/XUiFubenBabelTower/XUiGridBabelStageItem")
local XUiBabelTowerMainReproduce = require("XUi/XUiFubenBabelTower/XUiBabelTowerMainReproduce")

local SWITH_BG_TIME = 10 * XScheduleManager.SECOND
local SWITH_BG_INDEX = { 2, 1 }

local XUiBabelTowerMainNew = XLuaUiManager.Register(XLuaUi, "UiBabelTowerMainNew")

function XUiBabelTowerMainNew:OnAwake()
    self.FubenBabelTowerManager = XDataCenter.FubenBabelTowerManager
    self.ReproduceManager = self.FubenBabelTowerManager.GetReproduceManager()
    -- 当前活动id
    self.CurrentActivityNo = nil
    -- 当前活动总配置
    self.CurrentActivityTemplate = nil
    -- 章节Grid数组
    self.StageGridChapter = nil
    -- 复刻界面管理
    self.UiBabelTowerMainReproduce = XUiBabelTowerMainReproduce.New(self.PanelReprint)
    -- 初始化页面状态
    self:InitPanel()
    -- 初始化是否播放背景滚动动画
    self:InitIsPlayLoopBgAnimation()
    -- 注册ui事件
    self:RegisterUiEvents()
    self.ActivityType = XFubenBabelTowerConfigs.ActivityType.Normal
    XUiPanelAsset.New(self, self.PanelAsset
        , XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self:RegisterEventListeners()
end

function XUiBabelTowerMainNew:OnStart()
    self.ActivityType = self.FubenBabelTowerManager.GetMainUiType()
    self.CurrentActivityNo = self.FubenBabelTowerManager.GetCurrentActivityNo()
    self.CurrentActivityTemplate = XFubenBabelTowerConfigs.GetBabelTowerActivityTemplateById(self.CurrentActivityNo)
    if not self.CurrentActivityTemplate then
        return
    end
    -- 刷新排行榜按钮状态
    self.BtnRank.gameObject:SetActiveEx(self.CurrentActivityTemplate.RankType ~= XFubenBabelTowerConfigs.RankType.NoRank)
    -- 如果没有打开过帮助界面自动打开
    local value = self.FubenBabelTowerManager.GetBabelTowerPrefs(XFubenBabelTowerConfigs.HAS_PLAY_BEGINSTORY, 0)
    local hasPlay = value == 1
    if not hasPlay then
        -- XUiManager.ShowHelpTip("BabelTower")
        self.FubenBabelTowerManager.SaveBabelTowerPrefs(XFubenBabelTowerConfigs.HAS_PLAY_BEGINSTORY, 1)
    end
    -- 刷新关卡信息数据
    self:RefreshStageInfo()
    -- 显示复刻多少天后开放
    local reproduceIsOpen = self.ReproduceManager:GetIsOpen()
    self.PanelExtraLock.gameObject:SetActiveEx(not reproduceIsOpen)
    if not reproduceIsOpen then
        self.TxtExtraUnlockTime.text = self.ReproduceManager:GetStartTimeDes()
    end
    -- 刷新Reward数据
    self:RefreshRewardByActivity()
end

function XUiBabelTowerMainNew:OnEnable()
    XUiBabelTowerMainNew.Super.OnEnable(self)
    self:OnActivityStatusChanged()
    -- if not XLuaUiManager.IsUiShow("UiBabelTowerMainNew") then return end
    if self.UiProxy == nil then return end

    self:PlayAnimation("AnimStartEnable", function()
        XLuaUiManager.SetMask(false)
    end, function()
        XLuaUiManager.SetMask(true)
    end)

    self:PlayLoopBgAnimation()
    XRedPointManager.CheckOnce(self.OnCheckTaskRedPoint, self, { XRedPointConditions.Types.CONDITION_ACTIVITYBRIE_BABELTOWER_REWARD }
        , XFubenBabelTowerConfigs.ActivityType.Normal)
    -- 如果正常的到期了，复刻开启，直接打开复刻
    if not self.FubenBabelTowerManager.GetIsOpen() or self.ActivityType == XFubenBabelTowerConfigs.ActivityType.Extra then
        self:OnBtnUiReprintClicked()
    else
        self:UpdateReprintBtnState()
        -- 检查按钮小红点
        XRedPointManager.CheckOnceByButton(self.BtnUiReprint
            , { XRedPointConditions.Types.CONDITION_ACTIVITYBRIE_BABELTOWER_REWARD }, XFubenBabelTowerConfigs.ActivityType.Extra)
    end
    -- 每次巴别塔开放期间玩家首次进入巴别塔，检测玩家是否拥有前几期的巴别塔收藏品，满足品质条件则解锁部分内容，并弹出提示框告知玩家难度解锁
    self.FubenBabelTowerManager.CheckCollectionItemQuality()
end

function XUiBabelTowerMainNew:OnDisable()
    XUiBabelTowerMainNew.Super.OnDisable(self)
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiBabelTowerMainNew:OnDestroy()
    self:UnRegisterEventListeners()
end

--######################## 私有方法 ########################

function XUiBabelTowerMainNew:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, self.OnBtnMainUiClick)
    XUiHelper.RegisterClickEvent(self, self.BtnAchievement, self.OnBtnAchievementClick)
    XUiHelper.RegisterClickEvent(self, self.BtnRank, self.OnBtnRankClick)
    XUiHelper.RegisterClickEvent(self, self.BtnUiReprint, self.OnBtnUiReprintClicked)
    self:BindHelpBtn(self.BtnHelp, "BabelTower")
    self:ConnectSignal("UiBabelTowerMainReproduce", "Hide", self.OnReproduceUiHide, self)
end

function XUiBabelTowerMainNew:RegisterEventListeners()
    XEventManager.AddEventListener(XEventId.EVENT_BABEL_STAGE_INFO_ASYNC, self.RefreshStageInfo, self)
    XEventManager.AddEventListener(XEventId.EVENT_BABEL_RESET_STATUES_CHANGED, self.RefreshStageInfo, self)
    XEventManager.AddEventListener(XEventId.EVENT_BABEL_ACTIVITY_STATUS_CHANGED, self.OnActivityStatusChanged, self)
end

function XUiBabelTowerMainNew:UnRegisterEventListeners()
    XEventManager.RemoveEventListener(XEventId.EVENT_BABEL_STAGE_INFO_ASYNC, self.RefreshStageInfo, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_BABEL_RESET_STATUES_CHANGED, self.RefreshStageInfo, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_BABEL_ACTIVITY_STATUS_CHANGED, self.OnActivityStatusChanged, self)
end

function XUiBabelTowerMainNew:InitPanel()
    self.PanelAsset.gameObject:SetActiveEx(true)
    self.Bg.gameObject:SetActiveEx(true)
    self.PanelNormal.gameObject:SetActiveEx(true)
    self.PanelReprintBg.gameObject:SetActiveEx(false)
    self.PanelReprint.gameObject:SetActiveEx(false)
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

function XUiBabelTowerMainNew:UpdateReprintBtnState()
    if self.ReproduceManager:GetIsOpen() then
        self.BtnUiReprint:SetDisable(false)
    else
        self.BtnUiReprint:SetDisable(true)
    end
end

function XUiBabelTowerMainNew:OnBtnUiReprintClicked()
    -- 检查是否已开放
    if not self.ReproduceManager:GetIsOpen(true) then
        return
    end
    self.UiBabelTowerMainReproduce:Open()
    self.UiBabelTowerMainReproduce:RefreshReward(self.RootUi)
    self.PanelReprintBg.gameObject:SetActiveEx(true)
    self.PanelNormal.gameObject:SetActiveEx(false)
    self.ActivityType = XFubenBabelTowerConfigs.ActivityType.Extra
    self.FubenBabelTowerManager.SetMainUiType(self.ActivityType)
    -- 开启自动关闭检查
    local endTime = self.ReproduceManager:GetEndTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            self.ReproduceManager:HandleActivityEndTime()
        end
    end)
    self:_StopAutoCloseTimer()
    self:_StartAutoCloseTimer()
end

function XUiBabelTowerMainNew:OnReproduceUiHide()
    self.PanelNormal.gameObject:SetActiveEx(true)
    self.PanelReprintBg.gameObject:SetActiveEx(false)
    self.ActivityType = XFubenBabelTowerConfigs.ActivityType.Normal
    self.FubenBabelTowerManager.SetMainUiType(self.ActivityType)
    -- 关闭自动关闭检查
    self:SetAutoCloseInfo(nil)
    self:_StopAutoCloseTimer()
    -- 检查按钮小红点
    XRedPointManager.CheckOnceByButton(self.BtnUiReprint
    , { XRedPointConditions.Types.CONDITION_ACTIVITYBRIE_BABELTOWER_REWARD }, XFubenBabelTowerConfigs.ActivityType.Extra)
    self:UpdateReprintBtnState()
end

function XUiBabelTowerMainNew:OnBtnRankClick()
    self.FubenBabelTowerManager.GetRank(self.FubenBabelTowerManager.GetCurrentActivityNo(), function()
        XLuaUiManager.Open("UiFubenBabelTowerRank", XFubenBabelTowerConfigs.ActivityType.Normal)
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
    if not self.CurrentActivityNo or not self.FubenBabelTowerManager.IsInActivityTime(self.CurrentActivityNo) then
        XUiManager.TipMsg(CS.XTextManager.GetText("BabelTowerNoneOpen"))
        return
    end

    XLuaUiManager.Open("UiBabelTowerTask", XFubenBabelTowerConfigs.ActivityType.Normal)
end

function XUiBabelTowerMainNew:OnActivityStatusChanged()
    if not XLuaUiManager.IsUiShow("UiBabelTowerMainNew") then return end
    XDataCenter.FubenBabelTowerManager.HandleActivityEndTime(self.ActivityType)
end

-- function XUiBabelTowerMainNew:CheckPlayBeginStory()
--     local value = self.FubenBabelTowerManager.GetBabelTowerPrefs(XFubenBabelTowerConfigs.HAS_PLAY_BEGINSTORY, 0)
--     local hasPlay = value == 1
--     if not hasPlay and self.CurrentActivityNo then
--         local storyId = XFubenBabelTowerConfigs.GetActivityBeginStory(self.CurrentActivityNo)
--         -- 播放剧情
--         if storyId and storyId > 0 then
--             XDataCenter.MovieManager.PlayMovie(storyId)
--         end
--         self.FubenBabelTowerManager.SaveBabelTowerPrefs(XFubenBabelTowerConfigs.HAS_PLAY_BEGINSTORY, 1)
--     end
-- end

function XUiBabelTowerMainNew:RefreshAchievementTaskRedDot(count)
    self.RedAchievement.gameObject:SetActive(count >= 0)
end

function XUiBabelTowerMainNew:RefreshStageInfo()
    self:UpdateStageDetails()
    self:UpdateStageScores()
end

-- 更新当前分数和最大分数等级
function XUiBabelTowerMainNew:UpdateStageScores()
    local curScore, maxScore = self.FubenBabelTowerManager.GetCurrentActivityScores(XFubenBabelTowerConfigs.ActivityType.Normal)
    self.TxtTotalLevel.text = curScore
    -- self.TxtName.text = XFubenBabelTowerConfigs.GetActivityName(self.CurrentActivityNo)
    self.TxtHighest.text = XUiHelper.GetText("BabelTowerCurMaxScore", maxScore)
end

-- 更新章节数据
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

    local isStageUnlock, desc = self.FubenBabelTowerManager.IsBabelStageUnlock(stageId)
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
        local isUnlock = self.FubenBabelTowerManager.IsBabelStageGuideUnlock(stageId, currentSelectGuideId)
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

function XUiBabelTowerMainNew:RefreshRewardByActivity()
    self.ChapterRewardGrids = self.ChapterRewardGrids or {}
    local rewardId = XFubenBabelTowerConfigs.GetActivityRewardId(self.CurrentActivityNo)
    local rewards = XRewardManager.GetRewardList(rewardId)

    local rewardsNum = #rewards
    for i = 1, rewardsNum do
        local grid = self.ChapterRewardGrids[i]
        if not grid then
            local go = i == 1 and self.Grid256New or XUiHelper.Instantiate(self.Grid256New, self.PanelItem)
            grid = XUiGridCommon.New(self, go)
            self.ChapterRewardGrids[i] = grid
        end
        grid:Refresh(rewards[i])
        grid.GameObject:SetActiveEx(true)
    end
    for i = rewardsNum + 1, #self.ChapterRewardGrids do
        self.ChapterRewardGrids[i].GameObject:SetActiveEx(false)
    end
end 