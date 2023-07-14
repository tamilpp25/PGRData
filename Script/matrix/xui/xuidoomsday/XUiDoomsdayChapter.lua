local XUiGridDoomsdayStage = require("XUi/XUiDoomsday/XUiGridDoomsdayStage")

local MAX_STAGE_NUM = 5

local XUiDoomsdayChapter = XLuaUiManager.Register(XLuaUi, "UiDoomsdayChapter")

function XUiDoomsdayChapter:OnAwake()
    XUiHelper.NewPanelActivityAsset(
        {
            XDataCenter.ItemManager.ItemId.FreeGem,
            XDataCenter.ItemManager.ItemId.ActionPoint,
            XDataCenter.ItemManager.ItemId.Coin
        },
        self.PanelSpecialTool
    )

    self:AutoAddListener()

    self.StageParents = {}
    for i = 1, MAX_STAGE_NUM do
        table.insert(self.StageParents, self["Stage" .. i])
    end
end

function XUiDoomsdayChapter:OnStart()
    self.StageIds = XDataCenter.DoomsdayManager.GetActivityStageIds()
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

function XUiDoomsdayChapter:UpdateView()
    self:RefreshTemplateGrids(
        self.GridStageDoomsdayChapter,
        self.StageIds,
        self.StageParents,
        function()
            return XUiGridDoomsdayStage.New(handler(self, self.OnClickStage))
        end
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
    for index, inStageId in pairs(self.StageIds) do
        self:GetGrid(index):SetSelect(inStageId == stageId)
    end

    XLuaUiManager.Open("UiDoomsdayLineDetail", stageId, handler(self, self.OnStageDetailClose))
end

function XUiDoomsdayChapter:OnStageDetailClose()
    for index, inStageId in pairs(self.StageIds) do
        self:GetGrid(index):SetSelect(false)
    end
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
        end
    )
end

function XUiDoomsdayChapter:OnClickBtnTask()
    XLuaUiManager.Open("UiDoomsdayTask")
end

return XUiDoomsdayChapter
