local XUiGridDoomsdayStage = require("XUi/XUiDoomsday/XUiGridDoomsdayStage")

local MAX_STAGE_NUM = 6

-- 滑动列表滑动类型
local MovementType = {
    Elastic         = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic,
    Unrestricted    = CS.UnityEngine.UI.ScrollRect.MovementType.Unrestricted,
    Clamped         = CS.UnityEngine.UI.ScrollRect.MovementType.Clamped,
}

-- 关卡移动距离相关
local ChapterMoveX = {
    MAX    = XDataCenter.FubenMainLineManager.UiGridChapterMoveMaxX,
    MIN    = XDataCenter.FubenMainLineManager.UiGridChapterMoveMinX,
    TARGET = XDataCenter.FubenMainLineManager.UiGridChapterMoveTargetX
}

local XUiDoomsdayChapter = XLuaUiManager.Register(XLuaUi, "UiDoomsdayChapter")

function XUiDoomsdayChapter:OnAwake()
    --XUiHelper.NewPanelActivityAsset(
    --    {
    --        XDataCenter.ItemManager.ItemId.FreeGem,
    --        XDataCenter.ItemManager.ItemId.ActionPoint,
    --        XDataCenter.ItemManager.ItemId.Coin
    --    },
    --    self.PanelSpecialTool
    --)
    self.PanelSpecialTool.gameObject:SetActiveEx(false)
    self:InitTimer()
    self:AutoAddListener()

    self.StageParents = {}
    for i = 1, MAX_STAGE_NUM do
        local stage = self["Stage" .. i]
        if not stage then
            stage = self.PanelStageContent:Find("Stage" .. i)
            self["Stage" .. i] = stage
        end
        if not stage then
            XLog.Error("XUiDoomsdayChapter Init Stage Error, UiDoomsdayChapter.unity Not Found Stage"..i)
            break
        end
        table.insert(self.StageParents, stage)
    end
end

function XUiDoomsdayChapter:OnStart()
    self.StageIds = XDataCenter.DoomsdayManager.GetActivityStageIds()
    self.ChapterMember  = #self.StageIds
end

function XUiDoomsdayChapter:OnEnable()
    if self.IsEnd then
        return
    end
    if XDataCenter.DoomsdayManager.OnActivityEnd() then
        self.IsEnd = true
        return
    end

    self:UpdateView()
end

function XUiDoomsdayChapter:OnDisable()
    XCountDown.UnBindTimer(self, XCountDown.GTimerName.Doomsday)
end

function XUiDoomsdayChapter:OnGetEvents()
    return {
        XEventId.EVENT_DOOMSDAY_ACTIVITY_END
    }
end

function XUiDoomsdayChapter:OnNotify(evt, ...)
    if self.IsEnd then
        return
    end

    local args = {...}
    if evt == XEventId.EVENT_DOOMSDAY_ACTIVITY_END then
        if XDataCenter.DoomsdayManager.OnActivityEnd() then
            self.IsEnd = true
            return
        end
    end
end

function XUiDoomsdayChapter:AutoAddListener()
    self:BindHelpBtn(self.BtnHelp, "UiDoomsdayChapter")
    self:BindExitBtns()
    self.BtnTask.CallBack = handler(self, self.OnClickBtnTask)
end

function XUiDoomsdayChapter:InitTimer()
    XCountDown.RemoveTimer(XCountDown.GTimerName.Doomsday)
    local nowTime = XTime.GetServerNowTimestamp()
    local leftTime = XDataCenter.DoomsdayManager.GetEndTime() - nowTime
    if leftTime > 0 then
        XCountDown.CreateTimer(XCountDown.GTimerName.Doomsday, leftTime)
    end
end

function XUiDoomsdayChapter:UpdateView()
    self:RefreshTemplateGrids(
        self.GridStageDoomsdayChapter,
        self.StageIds,
        self.StageParents,
        function()
            return XUiGridDoomsdayStage.New(handler(self, self.OnClickStage))
        end,
        "GirdChapters"
    )

    --未开放的关卡不显示
    for index, stageId in ipairs(self.StageIds) do
        self:BindViewModelPropertyToObj(
            XDataCenter.DoomsdayManager.GetStageData(stageId),
            function(opening)
                self.StageParents[index].gameObject:SetActiveEx(opening)
            end,
            "_Opening"
        )
    end

    --任务红点
    XRedPointManager.AddRedPointEvent(
        self.BtnTask,
        function(_, count)
            self.BtnTask:ShowReddot(count >= 0)
        end,
        self,
        {XRedPointConditions.Types.XRedPointConditionDoomsdayTask}
    )

    self:UpdateLeftTime()
end

function XUiDoomsdayChapter:OnClickStage(stageId)
    local tmpGrid
    for index, inStageId in pairs(self.StageIds) do
        local grid = self:GetGrid(index, "GirdChapters")
        if inStageId == stageId then
            grid:SetSelect(true)
            tmpGrid = self["Stage"..index]
        else
            grid:SetSelect(false)
        end
    end
    self:DoMoveCenter(tmpGrid)

    XLuaUiManager.Open("UiDoomsdayLineDetail", stageId, handler(self, self.OnStageDetailClose))
end

function XUiDoomsdayChapter:DoMoveCenter(gridTrans)
    if not gridTrans then return end
    self.PaneStageList.movementType = MovementType.Unrestricted
    local gridTransform = gridTrans:GetComponent("RectTransform")
    local diffX = gridTransform.localPosition.x + self.PanelStageContent.localPosition.x;
    if diffX < ChapterMoveX.MIN or diffX > ChapterMoveX.MAX then
        local targetPosX = ChapterMoveX.TARGET - gridTransform.localPosition.x
        local targetPos = self.PanelStageContent.localPosition
        targetPos.x = targetPosX
        XLuaUiManager.SetMask(true)
        XUiHelper.DoMove(self.PanelStageContent, targetPos, XDataCenter.FubenMainLineManager.UiGridChapterMoveDuration, XUiHelper.EaseType.Sin, function()
            XLuaUiManager.SetMask(false)
        end)
    end
end

function XUiDoomsdayChapter:DoMoveBack()
    self.PaneStageList.movementType = MovementType.Elastic
end

function XUiDoomsdayChapter:OnStageDetailClose()
    for index, inStageId in pairs(self.StageIds) do
        self:GetGrid(index, "GirdChapters"):SetSelect(false)
    end
    self:DoMoveBack()
end

function XUiDoomsdayChapter:UpdateLeftTime()
    XCountDown.UnBindTimer(self, XCountDown.GTimerName.Doomsday)
    XCountDown.BindTimer(
        self,
        XCountDown.GTimerName.Doomsday,
        function(time)
            time = time > 0 and time or 0
            local timeText, timeSuffix = XUiHelper.GetTime(time, XUiHelper.TimeFormatType.DOOMSDAY)
            self.TxtDay.text = timeText
            self.TxtDaySuffix.text = timeSuffix

            for i = 1, self.ChapterMember do
                local grid = self:GetGrid(i, "GirdChapters")
                if grid and grid.RefreshState then
                    grid:RefreshState()
                end
            end
        end
    )
end

function XUiDoomsdayChapter:OnClickBtnTask()
    XLuaUiManager.Open("UiDoomsdayTask")
end

return XUiDoomsdayChapter
