local XUiFuben2023YuanXiaoTaskGrid = require("XUi/XUiSpecialTrainYuanXiao/YuanXiao2023/XUiFuben2023YuanXiaoTaskGrid")
local XUiFubenYuanXiao = require("XUi/XUiSpecialTrainYuanXiao/XUiFubenYuanXiao")

---@class XUiFuben2023YuanXiao:XUiFubenYuanXiao
local XUiFuben2023YuanXiao = XLuaUiManager.Register(XUiFubenYuanXiao, "UiFuben2023YuanXiao")

function XUiFuben2023YuanXiao:Ctor()
    self._TimerTask = false
    ---@type XUiFuben2023YuanXiaoTaskGrid[]
    self._GridTaskList = {}
end

function XUiFuben2023YuanXiao:OnAwake()
    XUiFuben2023YuanXiao.Super.OnAwake(self)
    self.TaskGrid.gameObject:SetActiveEx(false)
end

function XUiFuben2023YuanXiao:OnEnable()
    XUiFuben2023YuanXiao.Super.OnEnable(self)
    self:UpdateTask()
    self:UpdateTaskRefreshTime()
    self:UpdateRefreshTime()
    self:StartTimer()
    XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.Music, XLuaAudioManager.UiBasicsMusic.UiActivity_NewYear_BGM)
    XDataCenter.FubenSpecialTrainManager.YuanXiaoAutoGetReward()
    XEventManager.AddEventListener(XEventId.EVENT_TASK_SYNC, self.UpdateTask, self)
end

function XUiFuben2023YuanXiao:OnDisable()
    XUiFuben2023YuanXiao.Super.OnDisable(self)
    self:EndTimer()
    XEventManager.RemoveEventListener(XEventId.EVENT_TASK_SYNC, self.UpdateTask, self)
end

function XUiFuben2023YuanXiao:UpdateTask()
    local taskList = XDataCenter.FubenSpecialTrainManager.GetYuanXiaoDailyTaskGroup()
    for i = 1, #taskList do
        local grid = self._GridTaskList[i]
        if not grid then
            local uiGrid = XUiHelper.Instantiate(self.TaskGrid, self.TaskGrid.transform.parent)
            uiGrid.gameObject:SetActiveEx(true)
            grid = XUiFuben2023YuanXiaoTaskGrid.New(uiGrid)
            self._GridTaskList[i] = grid
        end
        grid:ResetData(taskList[i])
    end
    for i = #taskList + 1, #self._GridTaskList do
        local grid = self._GridTaskList[i]
        grid.GameObject:SetActiveEx(false)
    end
end

function XUiFuben2023YuanXiao:UpdateTaskRefreshTime()
    local refreshTime = XTime.GetSeverNextRefreshTime()
    local currentTime = XTime.GetServerNowTimestamp()
    local remainTime = refreshTime - currentTime
    local timeStr = XUiHelper.GetTime(remainTime, XUiHelper.TimeFormatType.DAY_HOUR)
    self.TaskTxt2.text = timeStr
end

function XUiFuben2023YuanXiao:StartTimer()
    if self._TimerTask then
        return
    end
    self._TimerTask = XScheduleManager.ScheduleForever(function()
        self:UpdateTaskRefreshTime()
        self:UpdateRefreshTime()
    end, XScheduleManager.SECOND)
end

function XUiFuben2023YuanXiao:EndTimer()
    if self._TimerTask then
        XScheduleManager.UnSchedule(self._TimerTask)
        self._TimerTask = false
    end
end

return XUiFuben2023YuanXiao