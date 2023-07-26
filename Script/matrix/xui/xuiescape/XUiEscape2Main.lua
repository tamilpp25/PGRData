local XUiEscape2ChapterGrid = require("XUi/XUiEscape/XUiEscape2ChapterGrid")
local CHAPTER_GRID_MAX_COUNT = 6    -- 当前界面章节最大数量

--大逃杀2期玩法主界面
local XUiEscape2Main = XLuaUiManager.Register(XLuaUi, "UiEscapeMain")

function XUiEscape2Main:OnAwake()
    self:InitPanelAsset()
    self:InitTask()
    self:InitDifficulty()
    self:InitChapter()
    self:AddBtnClickListener()
end

function XUiEscape2Main:OnStart()
    self._EscapeData = XDataCenter.EscapeManager.GetEscapeData()
    self:InitTimes()
end

function XUiEscape2Main:OnEnable()
    XUiEscape2Main.Super.OnEnable(self)
    self:Refresh()
    self:StartTimeUpdate()
end

function XUiEscape2Main:OnDisable()
    XUiEscape2Main.Super.OnDisable(self)
    self:StopTimeUpdate()
end

function XUiEscape2Main:OnGetEvents()
    return {
        XEventId.EVENT_FINISH_TASK,
        XEventId.EVENT_TASK_SYNC
    }
end

function XUiEscape2Main:OnNotify(event, ...)
    if event == XEventId.EVENT_FINISH_TASK or event == XEventId.EVENT_TASK_SYNC then
        self:UpdateTaskRedPoint()
    end
end

--region UiRefresh
function XUiEscape2Main:Refresh()
    self:UpdateTime()
    self:UpdateChapter()
    self:UpdateDifficulty()
    self:UpdateAllRedPoint()
end
--endregion

--region AutoClose
function XUiEscape2Main:InitTimes()
    self:SetAutoCloseInfo(XDataCenter.EscapeManager.GetActivityEndTime(), function(isClose)
        if isClose then
            XDataCenter.EscapeManager.HandleActivityEndTime()
        end
    end)
end
--endregion

--region Title
function XUiEscape2Main:InitPanelAsset()
    if self.PanelAsset then
        self.PanelAsset.gameObject:SetActiveEx(false)
    end
    --self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, 
    --        XDataCenter.ItemManager.ItemId.FreeGem,
    --        XDataCenter.ItemManager.ItemId.ActionPoint,
    --        XDataCenter.ItemManager.ItemId.Coin)
end

function XUiEscape2Main:StartTimeUpdate()
    self:StopTimeUpdate()
    self._TimeUpdateTimer = XScheduleManager.ScheduleForever(handler(self, self.UpdateTime),
            XScheduleManager.SECOND, 0)
end

function XUiEscape2Main:StopTimeUpdate()
    if self._TimeUpdateTimer then
        XScheduleManager.UnSchedule(self._TimeUpdateTimer)
    end
    self._TimeUpdateTimer = nil
end

function XUiEscape2Main:UpdateTime()
    if XTool.UObjIsNil(self.GameObject) then
        return
    end
    local endTime = XDataCenter.EscapeManager.GetActivityEndTime()
    local nowTime = XTime.GetServerNowTimestamp()
    local time, timeDesc = XUiHelper.GetTime(endTime - nowTime, XUiHelper.TimeFormatType.ESCAPE_ACTIVITY)
    self.TxtDay.text = time .. timeDesc
end
--endregion

--region Difficulty
function XUiEscape2Main:InitDifficulty()
    self.BtnNormal:SetDisable(false)
    self.BtnHard:SetDisable(false)
    self.BtnNormal.gameObject:SetActiveEx(false)
    self.BtnHard.gameObject:SetActiveEx(false)
    ---@type UnityEngine.Transform
    self.PanelNormal = XUiHelper.TryGetComponent(self.Transform, "FullScreenBackground/PanelNormal")
    ---@type UnityEngine.Transform
    self.PanelHard = XUiHelper.TryGetComponent(self.Transform, "FullScreenBackground/PanelHard")
    if self.PanelNormal then
        self.PanelNormal.gameObject:SetActiveEx(false)
    end
    if self.PanelHard then
        self.PanelHard.gameObject:SetActiveEx(false)
    end
    self:UpdateDifficulty()
end

function XUiEscape2Main:UpdateDifficulty()
    local difficulty = XDataCenter.EscapeManager.GetDifficulty()
    self.BtnNormal.gameObject:SetActiveEx(difficulty == XEscapeConfigs.Difficulty.Hard)
    self.BtnHard.gameObject:SetActiveEx(difficulty == XEscapeConfigs.Difficulty.Normal)
    self.RImgBg:SetRawImage(XEscapeConfigs.GetMainDifficultyBgUrl(difficulty))
    if self.PanelNormal then
        self.PanelNormal.gameObject:SetActiveEx(difficulty == XEscapeConfigs.Difficulty.Normal)
    end
    if self.PanelHard then
        self.PanelHard.gameObject:SetActiveEx(difficulty == XEscapeConfigs.Difficulty.Hard)
    end
end
--endregion

--region Chapter
function XUiEscape2Main:InitChapter()
    ---@type XUiEscape2ChapterGrid[]
    self._ChapterGridDir = {}
    for i = 1, CHAPTER_GRID_MAX_COUNT do
        self._ChapterGridDir[i] = XUiEscape2ChapterGrid.New(XUiHelper.Instantiate(self.GirdUiEscape2Stage.gameObject, self["Stage"..i].transform))
    end
    self.GirdUiEscape2Stage.gameObject:SetActiveEx(false)
end

function XUiEscape2Main:UpdateChapter()
    local chapterIdList = XEscapeConfigs.GetEscapeChapterIdListByDifficulty(XDataCenter.EscapeManager.GetDifficulty())
    for index, chapterId in ipairs(chapterIdList) do
        self._ChapterGridDir[index]:Refresh(chapterId, index)
        self._ChapterGridDir[index]:SetActive(true)
    end
    for i = #chapterIdList + 1, CHAPTER_GRID_MAX_COUNT do
        self._ChapterGridDir[i]:SetActive(false)
    end
end
--endregion

--region Task
function XUiEscape2Main:InitTask()
    local rewardId = XEscapeConfigs.GetMainShowRewardId()
    rewardId = rewardId and tonumber(rewardId)
    if not XTool.IsNumberValid(rewardId) then
        return
    end
    if XTool.UObjIsNil(self.Grid256New) or XTool.UObjIsNil(self.PanelRewardList) then
        return
    end

    local rewardItems = XRewardManager.GetRewardList(rewardId)
    local rewardGoodsList = XRewardManager.MergeAndSortRewardGoodsList(rewardItems)
    for i, reward in ipairs(rewardGoodsList) do
        local grid = i == 1 and self.Grid256New or XUiHelper.Instantiate(self.Grid256New, self.PanelRewardList)
        local gridCommon = XUiGridCommon.New(self, grid)
        gridCommon:Refresh(reward)
        if gridCommon.TxtName then  -- 不显示名称
            gridCommon.TxtName.gameObject:SetActiveEx(false)
        end
    end
end
--endregion

--region RedPoint
function XUiEscape2Main:UpdateAllRedPoint()
    self:UpdateTaskRedPoint()
end

function XUiEscape2Main:UpdateTaskRedPoint()
    self.BtnTask:ShowReddot(XDataCenter.EscapeManager.CheckTaskCanReward())
end
--endregion

--region BtnListener
function XUiEscape2Main:AddBtnClickListener()
    self:RegisterClickEvent(self.BtnBack, self.Close)
    self:RegisterClickEvent(self.BtnMainUi, function() XLuaUiManager.RunMain() end)
    self:BindHelpBtn(self.BtnHelp, XEscapeConfigs.GetHelpKey())

    self:RegisterClickEvent(self.BtnTask, self.OnBtnTaskClick)
    self:RegisterClickEvent(self.BtnNormal, self.OnBtnNormalDifficultyClick)
    self:RegisterClickEvent(self.BtnHard, self.OnBtnHardDifficultyClick)
end

function XUiEscape2Main:OnBtnTaskClick()
    XLuaUiManager.Open("UiEscapeTask")
end

function XUiEscape2Main:OnBtnNormalDifficultyClick()
    if XDataCenter.EscapeManager.SwitchDifficulty(XEscapeConfigs.Difficulty.Normal) then
        self:PlayAnimation("QieHuan")
        self:UpdateDifficulty()
        self:UpdateChapter()
    end
end

function XUiEscape2Main:OnBtnHardDifficultyClick()
    if XDataCenter.EscapeManager.SwitchDifficulty(XEscapeConfigs.Difficulty.Hard) then
        self:PlayAnimation("QieHuan")
        self:UpdateDifficulty()
        self:UpdateChapter()
    end
end
--endregion