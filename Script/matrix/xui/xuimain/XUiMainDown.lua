local XUiMainDown = XClass(nil, "XUiMainDown")

function XUiMainDown:Ctor(rootUi, ui)
    self.RootUi = rootUi
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self:InitButton()
end

function XUiMainDown:InitButton()
    if self.BtnNewRegression then
        self.BtnNewRegression.CallBack = function() XDataCenter.NewRegressionManager.OpenMainUi() end
        XRedPointManager.AddRedPointEvent(self.BtnNewRegression.ReddotObj, self.OnCheckNewRegressionRedPoint, self, { XRedPointConditions.Types.CONDITION_NEWREGRESSION_All_RED_POINT })
    end
end

function XUiMainDown:OnEnable()
    self:StartTimer()
    self:AddEventListener()
end

function XUiMainDown:OnDisable()
    self:StopTimer()
    self:RemoveEventListener()
end

function XUiMainDown:StartTimer()
    self:OnNewRegressionOpenStatusUpdate()
end

function XUiMainDown:StopTimer()
    self:StopNewRegressionTimer()
end

function XUiMainDown:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_NEW_REGRESSION_OPEN_STATUS_UPDATE, self.OnNewRegressionOpenStatusUpdate, self)
end

function XUiMainDown:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_NEW_REGRESSION_OPEN_STATUS_UPDATE, self.OnNewRegressionOpenStatusUpdate, self)
end

-----------------------新回归活动 begin------------------------
function XUiMainDown:OnNewRegressionOpenStatusUpdate()
    if not XDataCenter.NewRegressionManager.GetIsOpen() then
        self.BtnNewRegression.gameObject:SetActiveEx(false)
    else
        self:StopNewRegressionTimer()
        self:UpdateNewRegressionLeftTime()
        self:UpdateNewRegressionBtnIcon()
        self.BtnNewRegression.gameObject:SetActiveEx(true)

        self.NewRegressionTimer = XScheduleManager.ScheduleForever(function()
            self:UpdateNewRegressionLeftTime()
        end, XScheduleManager.SECOND, 0)
        XRedPointManager.CheckOnceByButton(self.BtnNewRegression, { XRedPointConditions.Types.CONDITION_NEWREGRESSION_All_RED_POINT })
    end
end

function XUiMainDown:UpdateNewRegressionBtnIcon()
    local state = XDataCenter.NewRegressionManager.GetActivityState()
    local isRegression = state == XNewRegressionConfigs.ActivityState.InRegression
    local nomalIconPath = isRegression and XNewRegressionConfigs.GetChildActivityConfig("MainRegressionNormalIconPath") or XNewRegressionConfigs.GetChildActivityConfig("MainInviteNormalIconPath")
    local pressIconPath = isRegression and XNewRegressionConfigs.GetChildActivityConfig("MainRegressionPressIconPath") or XNewRegressionConfigs.GetChildActivityConfig("MainInvitePressIconPath")
    self.NewRegressionNormalRawImage:SetRawImage(nomalIconPath)
    self.NewRegressionPressRawImage:SetRawImage(pressIconPath)
end

function XUiMainDown:StopNewRegressionTimer()
    if self.NewRegressionTimer then
        XScheduleManager.UnSchedule(self.NewRegressionTimer)
        self.NewRegressionTimer = nil
    end
end

function XUiMainDown:UpdateNewRegressionLeftTime()
    if not XDataCenter.NewRegressionManager.GetIsOpen() then
        self:StopNewRegressionTimer()
        self.BtnNewRegression.gameObject:SetActiveEx(false)
        return
    end

    self.TxtNewRegressionLeftTime.text = XDataCenter.NewRegressionManager.GetLeaveTimeStr(XUiHelper.TimeFormatType.NEW_REGRESSION_ENTRANCE)
end

function XUiMainDown:OnCheckNewRegressionRedPoint(count)
    self.BtnNewRegression:ShowReddot(count >= 0)
end
-----------------------新回归活动 end------------------------

return XUiMainDown