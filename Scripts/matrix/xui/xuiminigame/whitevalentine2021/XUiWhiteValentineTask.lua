-- 白色情人节约会活动任务界面
local XUiWhiteValentineTask = XLuaUiManager.Register(XLuaUi, "UiWhitedayTask")
local TaskList = require("XUi/XUiMiniGame/WhiteValentine2021/XUiWhiteValenTaskDynamicTable")
local XUiCommonAsset = require("XUi/XUiCommon/XUiCommonAsset")
function XUiWhiteValentineTask:OnAwake()
    XTool.InitUiObject(self)
    self.GridTask.gameObject:SetActiveEx(false)
    self.GameController = XDataCenter.WhiteValentineManager.GetGameController()
    self:InitButtons()
    self:InitAssetPanel()
    self:InitTaskList()
end

function XUiWhiteValentineTask:OnEnable()
    self:AddEventListeners()
    self:OnShowPanel()
    self:SetTimer()
end

function XUiWhiteValentineTask:OnDisable()
    self:StopTimer()
    self:RemoveEventListeners()
end

function XUiWhiteValentineTask:OnDestroy()
    self:StopTimer()
    self:RemoveEventListeners()
end
--================
--初始化按钮
--================
function XUiWhiteValentineTask:InitButtons()
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end
end
--================
--返回按钮
--================
function XUiWhiteValentineTask:OnBtnBackClick()
    self:Close()
end
--================
--主界面按钮
--================
function XUiWhiteValentineTask:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end
--================
--初始化右上角的资源道具面板
--================
function XUiWhiteValentineTask:InitAssetPanel()
    local AssetsList = {}
    local assetItem1 = {
        ShowType = XUiCommonAsset.ShowType.BagItem,
        ItemId = self.GameController:GetContributionItemId(),
    }
    table.insert(AssetsList, assetItem1)
    local AssetPanel = require("XUi/XUiCommon/XUiCommonAssetPanel")
    self.AssetPanel = AssetPanel.New(self.PanelAsset, AssetsList)
end
--================
--初始化界面面板
--================
function XUiWhiteValentineTask:InitTaskList()
    self.TaskList = TaskList.New(self.SViewTask, self)
end
--================
--显示界面时
--================
function XUiWhiteValentineTask:OnShowPanel()
    self.TaskList:UpdateData()
end
--================
--设置界面计时器
--================
function XUiWhiteValentineTask:SetTimer()
    self:StopTimer()
    self:SetResetTime()
    self.Timer = XScheduleManager.ScheduleForever(function()
            self:SetResetTime()
        end, XScheduleManager.SECOND, 0)
end
--================
--显示倒计时与处理倒计时完成时事件
--================
function XUiWhiteValentineTask:SetResetTime()
    local endTimeSecond = self.GameController:GetActivityEndTime()
    local now = XTime.GetServerNowTimestamp()
    local leftTime = endTimeSecond - now
    if leftTime <= 0 then
        self:OnActivityReset()
    end
end
--================
--停止界面计时器
--================
function XUiWhiteValentineTask:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

--================
--活动周期结束时弹回主界面
--================
function XUiWhiteValentineTask:OnActivityReset()
    self:StopTimer()
    XLuaUiManager.RunMain()
    XUiManager.TipMsg(CS.XTextManager.GetText("CommonActivityEnd"))
end

--================
--刷新任务列表
--================
function XUiWhiteValentineTask:RefreshTasks()
    self.TaskList:UpdateData()
end

--================
--增加事件监听
--================
function XUiWhiteValentineTask:AddEventListeners()
    if self.AlreadyAddEvents then return end
    self.AlreadyAddEvents = true
    XEventManager.AddEventListener(XEventId.EVENT_TASK_SYNC, self.RefreshTasks, self)
end
--================
--移除事件监听
--================
function XUiWhiteValentineTask:RemoveEventListeners()
    if not self.AlreadyAddEvents then return end
    self.AlreadyAddEvents = false
    XEventManager.RemoveEventListener(XEventId.EVENT_TASK_SYNC, self.RefreshTasks, self)
end