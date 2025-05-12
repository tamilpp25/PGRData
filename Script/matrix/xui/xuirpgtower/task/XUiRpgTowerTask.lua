local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
-- 兵法蓝图活动任务页面
local XUiRpgTowerTask = XLuaUiManager.Register(XLuaUi, "UiRpgTowerTask")
local TaskList = require("XUi/XUiRpgTower/Task/XUiRpgTowerTaskList")
function XUiRpgTowerTask:OnAwake()
    XTool.InitUiObject(self)
    XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.GridTask.gameObject:SetActiveEx(false)
    self:InitButtons()
    self:InitTaskList()
end

function XUiRpgTowerTask:OnEnable()
    self:AddEventListeners()
    self:OnShowPanel()
end

function XUiRpgTowerTask:OnDisable()
    self:StopTimer()
    self:RemoveEventListeners()
end

function XUiRpgTowerTask:OnDestroy()
    self:StopTimer()
    self:RemoveEventListeners()
end

function XUiRpgTowerTask:OnGetEvents()
    return { XEventId.EVENT_RPGTOWER_RESET, XEventId.EVENT_RPGTOWER_CHALLENGE_COUNT_CHANGE }
end

function XUiRpgTowerTask:OnNotify(evt, ...)
    local args = { ... }
    if evt == XEventId.EVENT_RPGTOWER_RESET then
        self:OnActivityReset()
    end
end

--================
--初始化按钮
--================
function XUiRpgTowerTask:InitButtons()
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end
end
--================
--返回按钮
--================
function XUiRpgTowerTask:OnBtnBackClick()
    self:Close()
end
--================
--主界面按钮
--================
function XUiRpgTowerTask:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

--================
--初始化界面面板
--================
function XUiRpgTowerTask:InitTaskList()
    self.TaskList = TaskList.New(self.SViewTask, self)
end
--================
--显示界面时
--================
function XUiRpgTowerTask:OnShowPanel()
    self.TaskList:UpdateData()
    --self:SetTimer()
end
--================
--设置界面计时器
--================
function XUiRpgTowerTask:SetTimer()
    self:StopTimer()
    self:SetResetTime()
    self.Timer = XScheduleManager.ScheduleForever(function()
            self:SetResetTime()
        end, XScheduleManager.SECOND, 0)
end
--================
--显示倒计时与处理倒计时完成时事件
--================
function XUiRpgTowerTask:SetResetTime()
    local endTimeSecond = XDataCenter.RpgTowerManager.GetEndTime()
    local now = XTime.GetServerNowTimestamp()
    local leftTime = endTimeSecond - now
    local remainTime = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
    self.TxtTime.text = CS.XTextManager.GetText("RpgTowerRemainTime", remainTime)
    if leftTime <= 0 then
        self:OnActivityReset()
    end
end
--================
--停止界面计时器
--================
function XUiRpgTowerTask:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

--================
--活动周期结束时弹回主界面
--================
function XUiRpgTowerTask:OnActivityReset()
    self:StopTimer()
    XLuaUiManager.RunMain()
    XUiManager.TipMsg(CS.XTextManager.GetText("RpgTowerFinished"))
end

--================
--刷新任务列表
--================
function XUiRpgTowerTask:RefreshTasks()
    self.TaskList:UpdateData()
end

--================
--增加事件监听
--================
function XUiRpgTowerTask:AddEventListeners()
    if self.AlreadyAddEvents then return end
    self.AlreadyAddEvents = true
    XEventManager.AddEventListener(XEventId.EVENT_TASK_SYNC, self.RefreshTasks, self)
end
--================
--移除事件监听
--================
function XUiRpgTowerTask:RemoveEventListeners()
    if not self.AlreadyAddEvents then return end
    self.AlreadyAddEvents = false
    XEventManager.RemoveEventListener(XEventId.EVENT_TASK_SYNC, self.RefreshTasks, self)
end