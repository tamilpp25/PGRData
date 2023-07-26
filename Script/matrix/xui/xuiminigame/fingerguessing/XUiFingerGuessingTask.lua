-- 猜拳小游戏活动任务界面
local XUiFingerGuessingTask = XLuaUiManager.Register(XLuaUi, "UiFingerGuessingTask")
local TaskList = require("XUi/XUiMiniGame/FingerGuessing/XUiFingerGuessingTaskDynamicTable")

function XUiFingerGuessingTask:OnAwake()
    XTool.InitUiObject(self)
    self.GridTask.gameObject:SetActiveEx(false)
    self.GameController = XDataCenter.FingerGuessingManager.GetGameController()
    self:InitButtons()
    self:InitPanelAsset()
    self:InitTaskList()
end
--================
--初始化按钮
--================
function XUiFingerGuessingTask:InitButtons()
    self.BtnBack.CallBack = function() self:OnClickBtnBack() end
    self.BtnMainUi.CallBack = function() self:OnClickBtnMainUi() end
end
--================
--点击返回按钮
--================
function XUiFingerGuessingTask:OnClickBtnBack()
    self:StopTimer()
    self:Close()
end
--================
--点击主界面按钮
--================
function XUiFingerGuessingTask:OnClickBtnMainUi()
    self:StopTimer()
    XLuaUiManager.RunMain()
end
--================
--初始化资源代币面板
--================
function XUiFingerGuessingTask:InitPanelAsset()
    local coinId = self.GameController:GetCoinItemId()
    local asset = XUiPanelAsset.New(self, self.PanelAsset, coinId)
    asset:RegisterJumpCallList({[1] = function()
                XLuaUiManager.Open("UiTip", coinId)
            end})
end
--================
--初始化界面面板
--================
function XUiFingerGuessingTask:InitTaskList()
    self.TaskList = TaskList.New(self.SViewTask, self)
end
--================
--显示界面时
--================
function XUiFingerGuessingTask:OnShowPanel()
    self.TaskList:UpdateData()
end
--================
--OnEnable 显示面板时
--================
function XUiFingerGuessingTask:OnEnable()
    self:StopTimer()
    self.Timer = XScheduleManager.ScheduleForever(function()
            self:SetGameTimer()
        end, XScheduleManager.SECOND, 0)
    self:AddEventListeners()
    self:OnShowPanel()
end
--================
--OnDisable 隐藏面板时
--================
function XUiFingerGuessingTask:OnDisable()
    self:StopTimer()
    self:RemoveEventListeners()
end
--================
--设置活动倒计时
--================
function XUiFingerGuessingTask:SetGameTimer()
    local endTimeSecond = self.GameController:GetActivityEndTime()
    local now = XTime.GetServerNowTimestamp()
    local leftTime = endTimeSecond - now
    if leftTime <= 0 then
        self:OnGameEnd()
    end
end
--================
--停止计时器
--================
function XUiFingerGuessingTask:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end
--================
--活动周期结束时弹回主界面
--================
function XUiFingerGuessingTask:OnGameEnd()
    if self.IsReseting then return end
    self.IsReseting = true
    self:StopTimer()
    XLuaUiManager.RunMain()
    XUiManager.TipMsg(CS.XTextManager.GetText("CommonActivityEnd"))
end
--================
--刷新任务列表
--================
function XUiFingerGuessingTask:RefreshTasks()
    self.TaskList:UpdateData()
end
--================
--增加事件监听
--================
function XUiFingerGuessingTask:AddEventListeners()
    if self.AlreadyAddEvents then return end
    self.AlreadyAddEvents = true
    XEventManager.AddEventListener(XEventId.EVENT_TASK_SYNC, self.RefreshTasks, self)
end
--================
--移除事件监听
--================
function XUiFingerGuessingTask:RemoveEventListeners()
    if not self.AlreadyAddEvents then return end
    self.AlreadyAddEvents = false
    XEventManager.RemoveEventListener(XEventId.EVENT_TASK_SYNC, self.RefreshTasks, self)
end