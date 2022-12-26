local CSXTextManagerGetText = CS.XTextManager.GetText
local MailMaxCount = CS.XGame.Config:GetInt("MailCountLimit")
local MailWillFullCount = CS.XGame.ClientConfig:GetInt("MailWillFullCount") --邮箱将满
local TipTimeLimitItemsLeftTime = CS.XGame.ClientConfig:GetInt("TipTimeLimitItemsLeftTime")    -- 限时道具提示时间
local TipBatteryLeftTime = CS.XGame.ClientConfig:GetInt("TipBatteryLeftTime")    -- 限时血清道具提示时间
local TipBatteryRefreshGap = 30     -- 限时血清道具刷新间隔
local XQualityManager = CS.XQualityManager.Instance
local LastMainUiChargeState = XUiMainChargeState.None
local BatteryComponent = CS.XUiBattery

XUiMainRightTop = XClass(nil, "XUiMainRightTop")

function XUiMainRightTop:Ctor(rootUi)
    self.RootUi = rootUi
    self.LastTipBatteryRefreshTime = 0
    self.Transform = rootUi.PanelRightTop.gameObject.transform
    XTool.InitUiObject(self)
    self:UpdateTimeLimitItemTipTimer()
    self.LowPowerValue = CS.XGame.ClientConfig:GetFloat("UiMainLowPowerValue")

    XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    --ClickEvent
    self.BtnSet.CallBack = function() self:OnBtnSet() end
    self.BtnMail.CallBack = function() self:OnBtnMail() end
    self.BtnPic.CallBack = function() self:OnBtnPic() end
    self.BtnWindows.CallBack = function() self:OnBtnWindows() end
    --RedPoint
    XRedPointManager.AddRedPointEvent(self.BtnSet, self.OnCheckSetNews, self, { XRedPointConditions.Types.CONDITION_MAIN_SET })
    XRedPointManager.AddRedPointEvent(self.BtnMail, self.OnCheckMailNews, self, { XRedPointConditions.Types.CONDITION_MAIN_MAIL })
    XRedPointManager.AddRedPointEvent(self.BtnPic, self.OnCheckPicNews, self, { XRedPointConditions.Types.CONDITION_PIC_COMPOSITION_TASK_FINISHED })
    XRedPointManager.AddRedPointEvent(self.BtnWindows, self.OnCheckWindowsNews, self, { XRedPointConditions.Types.CONDITION_WINDOWS_COMPOSITION_DAILY })
    

    XEventManager.AddEventListener(XEventId.EVENT_TIMELIMIT_ITEM_USE, function()
        self.LastTipBatteryRefreshTime = 0
    end)

    --Filter
    self:CheckFilterFunctions()
    self:CheckActivityInTime()
end

--事件监听
function XUiMainRightTop:OnNotify(evt)
    if evt == XEventId.EVENT_MAIL_COUNT_CHANGE then
        self:OnCheckMailWillFull()
    end
end

function XUiMainRightTop:OnEnable()
    self:UpdateChargeState()
    self:OnCheckMailWillFull()

    self.BatteryEffectSchedule = XScheduleManager.ScheduleForever(function()
        self:UpdateChargeState()
    end, 5 * XScheduleManager.SECOND)
    
    self:UpdateNowTimeTimer()
    self.LastTipBatteryRefreshTime = 0
    self.BatteryTimeSchedule = XScheduleManager.ScheduleForever(function()
        self:UpdateNowTimeTimer()
        self:UpdateTimeLimitItemTipTimer()
    end, XScheduleManager.SECOND)

    XEventManager.AddEventListener(XEventId.EVENT_PICCOMPOSITION_GET_MYDATA, self.OpenUiPicComposition, self)
end

function XUiMainRightTop:OnDisable()
    XScheduleManager.UnSchedule(self.BatteryEffectSchedule)
    XScheduleManager.UnSchedule(self.BatteryTimeSchedule)
    LastMainUiChargeState = XUiMainChargeState.None
    XEventManager.RemoveEventListener(XEventId.EVENT_PICCOMPOSITION_GET_MYDATA, self.OpenUiPicComposition, self)
end

function XUiMainRightTop:OnDestroy()
end

function XUiMainRightTop:CheckFilterFunctions()
    self.BtnSet.gameObject:SetActiveEx(not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.Setting))
    self.BtnMail.gameObject:SetActiveEx(not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.Mail))
    self.IsBtnPicCanOpen = not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.PicComposition)
    self.IsBtnWindowsCanOpen = not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.WindowsInlay)
end

function XUiMainRightTop:CheckActivityInTime()
    local windowsInlayActivityList = XDataCenter.MarketingActivityManager.GetWindowsInlayInTimeActivityList()
    local IsPicCompositionInTime = XDataCenter.MarketingActivityManager.CheckIsIntime()
    local picComposition = CS.XRemoteConfig.PicComposition

    self.BtnWindows.gameObject:SetActiveEx(#windowsInlayActivityList > 0 and self.IsBtnWindowsCanOpen)
    self.BtnPic.gameObject:SetActiveEx(#picComposition > 0 and IsPicCompositionInTime and self.IsBtnPicCanOpen)
end

--设置入口
function XUiMainRightTop:OnBtnSet()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Setting) then
        return
    end
    XLuaUiManager.Open("UiSet", false)
end

--邮件入口
function XUiMainRightTop:OnBtnMail()
    XLuaUiManager.Open("UiMail")
end

--内嵌浏览器入口
function XUiMainRightTop:OnBtnWindows()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.WindowsInlay) then
        return
    end
    self.BtnWindows:ShowReddot(false)
    XLuaUiManager.Open("UiWindowsInlay")
    XDataCenter.MarketingActivityManager.MarkWindowsInlayRedPoint()
end

--看图作文入口
function XUiMainRightTop:OnBtnPic()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.PicComposition) then
        return
    end
    XDataCenter.MarketingActivityManager.DelectTimeOverMemoDialogue()
    XDataCenter.MarketingActivityManager.InitMyCompositionDataList()
end

function XUiMainRightTop:OpenUiPicComposition(IsOpen)
    if IsOpen then
        XLuaUiManager.Open("UiPicComposition")
    else
        XUiManager.TipText("PicCompositionNetError")
    end
end

--更新时间
function XUiMainRightTop:UpdateNowTimeTimer()
    if XTool.UObjIsNil(self.TxtPhoneTime) then return end
    self.TxtPhoneTime.text = XTime.TimestampToGameDateTimeString(XTime.GetServerNowTimestamp(), "HH:mm")
end

-- 限时道具提示
function XUiMainRightTop:UpdateTimeLimitItemTipTimer()
    local nowTime = XTime.GetServerNowTimestamp()
    if nowTime - self.LastTipBatteryRefreshTime < TipBatteryRefreshGap then
        return
    end
    self.LastTipBatteryRefreshTime = nowTime

    -- 血清道具
    if not XTool.UObjIsNil(self.TxtBatteryLeftTime) then
        local leftTime = XDataCenter.ItemManager.GetBatteryMinLeftTime()
        if leftTime > 0 and leftTime <= TipBatteryLeftTime then
            self.TxtBatteryLeftTime.text = CSXTextManagerGetText("BatteryLeftTime", XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.MAINBATTERY))
            self.TxtBatteryLeftTime.gameObject:SetActiveEx(true)
        else
            self.TxtBatteryLeftTime.gameObject:SetActiveEx(false)
        end
    end

    --背包道具
    if not XTool.UObjIsNil(self.TxtItemLeftTime) then
        local leftTime = XDataCenter.ItemManager.GetTimeLimitItemsMinLeftTime()
        if leftTime > 0 and leftTime <= TipTimeLimitItemsLeftTime then
            local timeStr = XUiHelper.GetBagTimeLimitTimeStrAndBg(leftTime)
            self.TxtItemLeftTime.text = CSXTextManagerGetText("TimeLimitItemLeftTime", timeStr)
            self.TxtItemLeftTime.gameObject:SetActiveEx(true)
        else
            self.TxtItemLeftTime.gameObject:SetActiveEx(false)
        end
    end
end

function XUiMainRightTop:OnCheckPicNews(count)--看图作文
    self.BtnPic:ShowReddot(count >= 0 and XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.PicComposition))
end

function XUiMainRightTop:OnCheckWindowsNews(count)--内嵌浏览器
    self.BtnWindows:ShowReddot(count >= 0 and XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.WindowsInlay))
end

--设置红点（自定义按键冲突）
function XUiMainRightTop:OnCheckSetNews(count)
    self.BtnSet:ShowReddot(count >= 0)
end

--邮件红点
function XUiMainRightTop:OnCheckMailNews(count)
    self.BtnMail:ShowReddot(count >= 0)
end

--邮件将满
function XUiMainRightTop:OnCheckMailWillFull()
    local count = XDataCenter.MailManager.GetMailCount()
    self.TxtMailWillFull.gameObject:SetActiveEx(count >= MailWillFullCount)
    if count >= MailMaxCount then
        self.TxtMailWillFull.text = CSXTextManagerGetText("MailIsFull")
    else
        self.TxtMailWillFull.text = CSXTextManagerGetText("MailWillFull")
    end
end

function XUiMainRightTop:UpdateChargeMark()
    if LastMainUiChargeState == XUiMainChargeState.Charge then
        self.LowPowerMarkFight.gameObject:SetActiveEx(false)
        self.LowPowerMarkBuilding.gameObject:SetActiveEx(false)
    elseif LastMainUiChargeState == XUiMainChargeState.Enough then
        self.LowPowerMarkFight.gameObject:SetActiveEx(false)
        self.LowPowerMarkBuilding.gameObject:SetActiveEx(false)
    elseif LastMainUiChargeState == XUiMainChargeState.LowPower then
        self.LowPowerMarkFight.gameObject:SetActiveEx(true)
        self.LowPowerMarkBuilding.gameObject:SetActiveEx(true)
    end
end

--更新主页面低电量状态效果
--打开窗口电量状态判断
function XUiMainRightTop:UpdateChargeState()
    if XQualityManager.IsSimulator and not BatteryComponent.DebugMode then
        return
    end

    local curMainUiChargeState = XUiMainChargeState.None
    if BatteryComponent.IsCharging then
        curMainUiChargeState = XUiMainChargeState.Charge
    else
        if BatteryComponent.BatteryLevel > self.LowPowerValue then
            curMainUiChargeState = XUiMainChargeState.Enough
        else
            curMainUiChargeState = XUiMainChargeState.LowPower
        end
    end

    if LastMainUiChargeState == XUiMainChargeState.None then --初始状态
        if curMainUiChargeState == XUiMainChargeState.Charge or curMainUiChargeState == XUiMainChargeState.Enough then -- 从无状态到指定状态
            self.RootUi:ChangeLowPowerState(self.RootUi.LowPowerState.Full)
        elseif curMainUiChargeState == XUiMainChargeState.LowPower then
            self.RootUi:ChangeLowPowerState(self.RootUi.LowPowerState.Low)
        end
    elseif LastMainUiChargeState == XUiMainChargeState.Charge or LastMainUiChargeState == XUiMainChargeState.Enough then -- 从电量充足或者充电到低电量
        if curMainUiChargeState == XUiMainChargeState.LowPower then
            self.RootUi:ChangeLowPowerState(self.RootUi.LowPowerState.FullToLow)
        else
            self.RootUi:ChangeLowPowerState(self.RootUi.LowPowerState.Full)
        end
    elseif LastMainUiChargeState == XUiMainChargeState.LowPower then -- 从低电量到充电或者电量充足
        if curMainUiChargeState == XUiMainChargeState.Charge or curMainUiChargeState == XUiMainChargeState.Enough then
            self.RootUi:ChangeLowPowerState(self.RootUi.LowPowerState.LowToFull)
        else
            self.RootUi:ChangeLowPowerState(self.RootUi.LowPowerState.Low)
        end
    end

    LastMainUiChargeState = curMainUiChargeState
    self:UpdateChargeMark()
end