local XUiMainDown = XClass(nil, "XUiMainDown")

function XUiMainDown:Ctor(rootUi, ui)
    self.RootUi = rootUi
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    if self.BtnPassport then
        self.BtnPassport.CallBack = function() self:OnBtnPassportClick() end
    end

    --RedPoint
    XRedPointManager.AddRedPointEvent(self.BtnPassport.ReddotObj, self.OnCheckPassportRedPoint, self, { XRedPointConditions.Types.CONDITION_PASSPORT_RED })
end

function XUiMainDown:OnEnable()
    self:OnPassportOpenStatusUpdate()
end

function XUiMainDown:OnDisable()
    self:StopPassportTimer()
end

--战斗通行证
function XUiMainDown:OnBtnPassportClick()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Passport) then
        return
    end
    XLuaUiManager.Open("UiPassport")
end

function XUiMainDown:OnPassportOpenStatusUpdate()
    if XDataCenter.PassportManager.IsActivityClose() then
        self.BtnPassport.gameObject:SetActiveEx(false)
    else
        self:StopPassportTimer()
        self:UpdatePassportLeftTime()
        self.PassportTimer = XScheduleManager.ScheduleForever(function()
            self:UpdatePassportLeftTime()
        end, XScheduleManager.SECOND, 0)
    end
end

function XUiMainDown:StopPassportTimer()
    if self.PassportTimer then
        XScheduleManager.UnSchedule(self.PassportTimer)
        self.PassportTimer = nil
    end
end

function XUiMainDown:UpdatePassportLeftTime()
    local timeId = XPassportConfigs.GetPassportActivityTimeId()
    if XFunctionManager.CheckInTimeByTimeId(timeId) then
        self.BtnPassport.gameObject:SetActiveEx(true)
    elseif XDataCenter.PassportManager.IsActivityClose() then
        self:StopPassportTimer()
        self:OnPassportOpenStatusUpdate()
    else
        self.BtnPassport.gameObject:SetActiveEx(false)
    end
end

--战斗通行证红点
function XUiMainDown:OnCheckPassportRedPoint(count)
    self.BtnPassport:ShowReddot(count >= 0)
end

return XUiMainDown