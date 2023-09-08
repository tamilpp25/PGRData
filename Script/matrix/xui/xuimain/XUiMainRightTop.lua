local CSXTextManagerGetText = CS.XTextManager.GetText
local TipTimeLimitItemsLeftTime = CS.XGame.ClientConfig:GetInt("TipTimeLimitItemsLeftTime")    -- 限时道具提示时间
local TipBatteryLeftTime = CS.XGame.ClientConfig:GetInt("TipBatteryLeftTime")    -- 限时血清道具提示时间
local TipBatteryRefreshGap = 30     -- 限时血清道具刷新间隔
local XQualityManager = CS.XQualityManager.Instance
local LastMainUiChargeState = XUiMainChargeState.None
local BatteryComponent = CS.XUiBattery
local DateStartTime = CS.XGame.ClientConfig:GetString("BackgroundChangeTimeStr")
local DateEndTime = CS.XGame.ClientConfig:GetString("BackgroundChangeTimeEnd")

--主界面会频繁打开，采用常量缓存
local RedPointConditionGroup = {
    Pic = {
        XRedPointConditions.Types.CONDITION_PIC_COMPOSITION_TASK_FINISHED
    },
    Windows = {
        XRedPointConditions.Types.CONDITION_WINDOWS_COMPOSITION_DAILY
    }
}

local XUiMainPanelBase = require("XUi/XUiMain/XUiMainPanelBase")
---@class XUiMainRightTop:XUiMainPanelBase
local XUiMainRightTop = XClass(XUiMainPanelBase, "XUiMainRightTop")

function XUiMainRightTop:OnStart(rootUi)
    ---@type XUiMain
    self.RootUi = rootUi
    self:ResetBatteryTime()
    -- self.Transform = rootUi.PanelRightTop.gameObject.transform
    -- XTool.InitUiObject(self)
    self:UpdateTimeLimitItemTipTimer()
    self.LowPowerValue = CS.XGame.ClientConfig:GetFloat("UiMainLowPowerValue")

    XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    --ClickEvent
    self.BtnPic.CallBack = function() self:OnBtnPic() end
    self.BtnWindows.CallBack = function() self:OnBtnWindows() end
    
    --RedPoint
    self:AddRedPointEvent(self.BtnPic, self.OnCheckPicNews, self, RedPointConditionGroup.Pic)
    self:AddRedPointEvent(self.BtnWindows, self.OnCheckWindowsNews, self, RedPointConditionGroup.Windows)

    --Filter
    self:CheckFilterFunctions()
    self:CheckActivityInTime()
end

--事件监听
function XUiMainRightTop:OnNotify(evt)
    
end

function XUiMainRightTop:OnEnable()
    if not self.IsPreview then
        --延迟更新，解决可能存在的当帧问题（Mono状态未更新）
        XScheduleManager.Schedule(function()
            self:UpdateSceneState()
        end,0.1*XScheduleManager.SECOND,1,0)
    end
    
    self:ResetBatteryTime()

    self.BatteryEffectSchedule = XScheduleManager.ScheduleForever(function()
        self:UpdateSceneState()
    end, 5 * XScheduleManager.SECOND)

    self.BatteryTimeSchedule = XScheduleManager.ScheduleForever(function()
        self:UpdateNowTimeTimer()
        self:UpdateTimeLimitItemTipTimer()
    end, XScheduleManager.SECOND)
    

    XEventManager.AddEventListener(XEventId.EVENT_PICCOMPOSITION_GET_MYDATA, self.OpenUiPicComposition, self)
    
    XEventManager.AddEventListener(XEventId.EVENT_SCENE_PREVIEW, self.OnBackGroupPreview, self)
    XEventManager.AddEventListener(XEventId.EVENT_SCENE_UIMAIN_STATE_CHANGE, self.PreviewUpdateChargeMark, self)
    XEventManager.AddEventListener(XEventId.EVENT_TIMELIMIT_ITEM_USE, self.ResetBatteryTime, self)
end

function XUiMainRightTop:OnDisable()
    
    XScheduleManager.UnSchedule(self.BatteryEffectSchedule)
    if self.BatteryTimeSchedule then
        XScheduleManager.UnSchedule(self.BatteryTimeSchedule)
        self.BatteryTimeSchedule = nil
    end
    LastMainUiChargeState = XUiMainChargeState.None
    self.RootUi:ChangeLowPowerState(self.RootUi.LowPowerState.None)
    XEventManager.RemoveEventListener(XEventId.EVENT_PICCOMPOSITION_GET_MYDATA, self.OpenUiPicComposition, self)
    
    XEventManager.RemoveEventListener(XEventId.EVENT_SCENE_PREVIEW, self.OnBackGroupPreview, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SCENE_UIMAIN_STATE_CHANGE, self.PreviewUpdateChargeMark, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_TIMELIMIT_ITEM_USE, self.ResetBatteryTime, self)
end

function XUiMainRightTop:OnDestroy()
end

function XUiMainRightTop:CheckFilterFunctions()
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
            self.TxtBatteryLeftTime.transform.parent.gameObject:SetActiveEx(true)
        else
            self.TxtBatteryLeftTime.transform.parent.gameObject:SetActiveEx(false)
        end
    end

    --背包道具
    if not XTool.UObjIsNil(self.TxtItemLeftTime) then
        local leftTime = XDataCenter.ItemManager.GetTimeLimitItemsMinLeftTime()
        if leftTime > 0 and leftTime <= TipTimeLimitItemsLeftTime then
            local timeStr = XUiHelper.GetBagTimeLimitTimeStrAndBg(leftTime)
            self.TxtItemLeftTime.text = CSXTextManagerGetText("TimeLimitItemLeftTime", timeStr)
            self.TxtItemLeftTime.transform.parent.gameObject:SetActiveEx(true)
        else
            self.TxtItemLeftTime.transform.parent.gameObject:SetActiveEx(false)
        end
    end
end

function XUiMainRightTop:ResetBatteryTime()
    self.LastTipBatteryRefreshTime = 0
end

function XUiMainRightTop:OnCheckPicNews(count)--看图作文
    self.BtnPic:ShowReddot(count >= 0 and XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.PicComposition))
end

function XUiMainRightTop:OnCheckWindowsNews(count)--内嵌浏览器
    self.BtnWindows:ShowReddot(count >= 0 and XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.WindowsInlay))
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
    
    --v2.5屏蔽掉Debug特殊赋值
    --[[
    if XQualityManager.IsSimulator and not BatteryComponent.DebugMode then
        return nil
    end
    --]]
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
    return curMainUiChargeState
end

-- v1.29 更新主页面昼夜状态效果
function XUiMainRightTop:UpdateDateState()
    if XQualityManager.IsSimulator and not BatteryComponent.DebugMode then
        return nil
    end

    local startTime = XTime.ParseToTimestamp(DateStartTime)
    local endTime = XTime.ParseToTimestamp(DateEndTime)
    local nowTime = XTime.ParseToTimestamp(CS.System.DateTime.Now:ToLocalTime():ToString())

    local curMainUiChargeState = XUiMainChargeState.None
    if startTime > nowTime and nowTime > endTime then
        curMainUiChargeState = XUiMainChargeState.Enough
    else
        curMainUiChargeState = XUiMainChargeState.LowPower
    end
    return curMainUiChargeState
end

-- v1.29 新增主界面场景状态切换类型
function XUiMainRightTop:UpdateSceneState()
    local curMainUiChargeState
    
    local curSceneId = XDataCenter.PhotographManager.GetCurSceneId()
    local type = XPhotographConfigs.GetBackgroundTypeById(curSceneId)
    if type == XPhotographConfigs.BackGroundType.PowerSaved then
        curMainUiChargeState = self:UpdateChargeState()
    else
        curMainUiChargeState = self:UpdateDateState()
    end

    if not curMainUiChargeState or curMainUiChargeState == LastMainUiChargeState then
        return
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
    -- 省电模式需要显示省电标签
    if type == XPhotographConfigs.BackGroundType.PowerSaved then
        self:UpdateChargeMark()
    elseif type == XPhotographConfigs.BackGroundType.Date then
        self.LowPowerMarkFight.gameObject:SetActiveEx(false)
        self.LowPowerMarkBuilding.gameObject:SetActiveEx(false)
    elseif type==XPhotographConfigs.BackGroundType.Normal then
        self.LowPowerMarkFight.gameObject:SetActiveEx(false)
        self.LowPowerMarkBuilding.gameObject:SetActiveEx(false)
    end
end

-- v1.29 场景预览，预览状态切换模式标签
function XUiMainRightTop:PreviewUpdateChargeMark()
    local curSceneId = XDataCenter.PhotographManager.GetCurSceneId()
    local type = XPhotographConfigs.GetBackgroundTypeById(curSceneId)
    -- 省电模式需要显示省电标签
    if type == XPhotographConfigs.BackGroundType.PowerSaved then
        if XDataCenter.PhotographManager.GetPreviewState() == XPhotographConfigs.BackGroundState.Full then --满电状态
            self.LowPowerMarkFight.gameObject:SetActiveEx(false)
            self.LowPowerMarkBuilding.gameObject:SetActiveEx(false)
        else
            self.LowPowerMarkFight.gameObject:SetActiveEx(true)
            self.LowPowerMarkBuilding.gameObject:SetActiveEx(true)
        end
    elseif type == XPhotographConfigs.BackGroundType.Date then
        self.LowPowerMarkFight.gameObject:SetActiveEx(false)
        self.LowPowerMarkBuilding.gameObject:SetActiveEx(false)
    elseif type==XPhotographConfigs.BackGroundType.Normal then
        self.LowPowerMarkFight.gameObject:SetActiveEx(false)
        self.LowPowerMarkBuilding.gameObject:SetActiveEx(false)
    end
end

-----------------------战斗通行证 begin------------------------




-- v1.29 关场景模式改变监听
function XUiMainRightTop:OnBackGroupPreview() 
    XScheduleManager.UnSchedule(self.BatteryEffectSchedule) 
    XScheduleManager.UnSchedule(self.BatteryTimeSchedule)
    self.IsPreview=true
end

-----------------------战斗通行证 end------------------------
return XUiMainRightTop