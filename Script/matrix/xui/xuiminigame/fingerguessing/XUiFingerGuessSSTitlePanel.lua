-- 选择关卡界面标题面板控件
local XUiFingerGuessSSTitlePanel = XClass(nil, "XUiFingerGuessSSTitlePanel")
--================
--构造函数
--================
function XUiFingerGuessSSTitlePanel:Ctor(gameObject, rootUi)
    self.RootUi = rootUi
    XTool.InitUiObjectByUi(self, gameObject)
    self:InitPanel()
end
--================
--初始化面板
--================
function XUiFingerGuessSSTitlePanel:InitPanel()
    if self.TxtTitle then
        self.TxtTitle.text = self.RootUi.GameController:GetName()
    end
    self:RefreshTime()
end
--================
--刷新活动倒计时
--================
function XUiFingerGuessSSTitlePanel:RefreshTime()
    local endTimeSecond = self.RootUi.GameController:GetActivityEndTime()
    local now = XTime.GetServerNowTimestamp()
    local leftTime = endTimeSecond - now
    self:SetTxtTime(XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY))
end
--================
--设置倒计时文本
--================
function XUiFingerGuessSSTitlePanel:SetTxtTime(text)
    self.TxtTime.text = CS.XTextManager.GetText("CommonActivityTimeStr", text)
end
--================
--OnEnable 显示面板时
--================
function XUiFingerGuessSSTitlePanel:OnEnable()
    self:StopTimer()
    self.Timer = XScheduleManager.ScheduleForever(function()
            self:SetGameTimer()
        end, XScheduleManager.SECOND, 0)
end
--================
--OnDisable 隐藏面板时
--================
function XUiFingerGuessSSTitlePanel:OnDisable()
    self:StopTimer()
end
--================
--设置活动倒计时
--================
function XUiFingerGuessSSTitlePanel:SetGameTimer()
    local endTimeSecond = self.RootUi.GameController:GetActivityEndTime()
    local now = XTime.GetServerNowTimestamp()
    local leftTime = endTimeSecond - now
    self:SetTxtTime(XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY))
    if leftTime <= 0 then
        if self.IsReseting then return end
        self.IsReseting = true
        self:StopTimer()
        self.RootUi:OnGameEnd()
    end
end
--================
--停止计时器
--================
function XUiFingerGuessSSTitlePanel:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end
return XUiFingerGuessSSTitlePanel