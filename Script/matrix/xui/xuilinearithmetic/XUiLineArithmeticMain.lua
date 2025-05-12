local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiLineArithmeticMainChapterGrid = require("XUi/XUiLineArithmetic/XUiLineArithmeticMainChapterGrid")

---@class XUiLineArithmeticMain : XLuaUi
---@field _Control XLineArithmeticControl
local XUiLineArithmeticMain = XLuaUiManager.Register(XLuaUi, "UiLineArithmeticMain")

function XUiLineArithmeticMain:Ctor()
    self._Timer = false
    self._GridChapters = {}
    self._TimerReward = false
    self._DurationShowReward = 5 * XScheduleManager.SECOND
end

function XUiLineArithmeticMain:OnAwake()
    self:BindExitBtns()
    XUiHelper.RegisterClickEvent(self, self.BtnReward, self.OnClickTask)
    self:BindHelpBtn(self.BtnHelp, "LineArithmeticHelp")
end

function XUiLineArithmeticMain:OnStart()
    self:UpdateReward()
end

function XUiLineArithmeticMain:OnEnable()
    if not self:UpdateTime() then
        return
    end
    if not self._Timer then
        self._Timer = XScheduleManager.ScheduleForever(function()
            self:UpdateTime()
        end, XScheduleManager.SECOND)
    end
    self:ShowReward()
    self:UpdateChapter()
    self:UpdateTask()
    
    if not self._TimerLock then
        if not self:CheckUnlockAll() then
            -- 固定时间刷新一次, 以解锁
            self._TimerLock = XScheduleManager.ScheduleForever(function()
                self:UpdateChapter()
                self:CheckUnlockAll()
            end, XScheduleManager.SECOND * 30)
        end
    end
end

function XUiLineArithmeticMain:OnDisable()
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = false
    end
    if self._TimerLock then
        XScheduleManager.UnSchedule(self._TimerLock)
        self._TimerLock = false
    end
    if self._TimerReward then
        XScheduleManager.UnSchedule(self._TimerReward)
        self._TimerReward = false
    end
end

function XUiLineArithmeticMain:UpdateTime()
    if self._Control:UpdateTime() then
        local uiData = self._Control:GetUiData()
        self.TxtTime.text = uiData.Time
        return true
    end
    return false
end

function XUiLineArithmeticMain:UpdateChapter()
    self._Control:UpdateChapter()
    local chapters = self._Control:GetUiData().Chapter
    for i = 1, #chapters do
        ---@type XUiLineArithmeticMainChapterGrid
        local grid = self._GridChapters[i]
        if not grid then
            local ui = self["GridChapter" .. i]
            if not ui then
                XLog.Error("[XUiLineArithmeticMain] 章节节点不够了， 加多个吧:", i)
                break
            end
            grid = XUiLineArithmeticMainChapterGrid.New(ui, self)
            self._GridChapters[i] = grid
        end
        grid:Open()
        grid:Update(chapters[i])
    end
    for i = #chapters + 1, #self._GridChapters do
        local grid = self._GridChapters[i]
        grid:Close()
    end
end

function XUiLineArithmeticMain:UpdateReward()
    self._Control:UpdateReward()
    local rewards = self._Control:GetUiData().RewardOnMainUi
    XUiHelper.RefreshCustomizedList(self.Grid256New.transform.parent, self.Grid256New, #rewards, function(index, grid)
        ---@type XUiGridCommon
        local grid = XUiGridCommon.New(self, grid)
        grid:Refresh(rewards[index])
        grid:SetName("")
    end)
end

function XUiLineArithmeticMain:UpdateTask()
    local taskDatas = XDataCenter.TaskManager.GetLineArithmeticTaskList()
    local isShowRedDot = false
    for i = 1, #taskDatas do
        local taskData = taskDatas[i]
        if taskData.State == XDataCenter.TaskManager.TaskState.Achieved then
            isShowRedDot = true
            break
        end
    end
    self.BtnReward:ShowReddot(isShowRedDot)
end

function XUiLineArithmeticMain:OnClickTask()
    XLuaUiManager.Open("UiLineArithmeticTask")
end

function XUiLineArithmeticMain:ShowReward()
    self.PanelItem.gameObject:SetActiveEx(true)
    self._TimerReward = XScheduleManager.ScheduleOnce(function()
        self._TimerReward = false
        self.PanelItem.gameObject:SetActiveEx(false)
    end, self._DurationShowReward)
end

function XUiLineArithmeticMain:CheckUnlockAll()
    local chapters = self._Control:GetUiData().Chapter
    local isUnlockAll = true
    for i = 1, #chapters do
        if not chapters[i].IsOpen then
            isUnlockAll = false
        end
    end
    if isUnlockAll then
        if self._TimerLock then
            XScheduleManager.UnSchedule(self._TimerLock)
            self._TimerLock = false
        end
    end
    return isUnlockAll
end

return XUiLineArithmeticMain
