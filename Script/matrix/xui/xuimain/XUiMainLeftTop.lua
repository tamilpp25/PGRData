local XUiMainPanelBase = require("XUi/XUiMain/XUiMainPanelBase")
---@class XUiMainLeftTop : XUiMainPanelBase
local XUiMainLeftTop = XClass(XUiMainPanelBase, "XUiMainLeftTop")

--local Vector3 = CS.UnityEngine.Vector3
--local DOTween = CS.DG.Tweening.DOTween

--local MusicPlayerTextMoveSpeed = CS.XGame.ClientConfig:GetFloat("MusicPlayerMainViewTextMoveSpeed")
--local MusicPlayerTextMovePauseInterval = CS.XGame.ClientConfig:GetFloat("MusicPlayerMainViewTextMovePauseInterval")

local RegressionMainViewFreshTimeInterval = CS.XGame.ClientConfig:GetInt("RegressionMainViewFreshTimeInterval")

--主界面会频繁打开，采用常量缓存
local RedPointConditionGroup = {
    --玩家信息
    RoleInfo = {
        XRedPointConditions.Types.CONDITION_PLAYER_ACHIEVE, XRedPointConditions.Types.CONDITION_PLAYER_SETNAME,
        XRedPointConditions.Types.CONDITION_EXHIBITION_NEW, XRedPointConditions.Types.CONDITION_HEADPORTRAIT_RED,
        XRedPointConditions.Types.CONDITION_MEDAL_RED, XRedPointConditions.Types.CONDITION_PLAYER_BIRTHDAY,
        XRedPointConditions.Types.CONDITION_FEEDBACK_RED, XRedPointConditions.Types.CONDITION_PLAYER_GENDERSET,
    },
    --战令
    Passport = {
        XRedPointConditions.Types.CONDITION_PASSPORT_RED
    },
    --回归
    Regression = {
        XRedPointConditions.Types.CONDITION_REGRESSION
    },
    --新版回归
    NewRegression = {
        XRedPointConditions.Types.CONDITION_NEWREGRESSION_All_RED_POINT
    },
    --第三期回归
    NewRegression3rd = {
        XRedPointConditions.Types.CONDITION_REGRESSION3_ALL
    },
    --引导任务
    Guide = {
        XRedPointConditions.Types.CONDITION_MAIN_NEWBIE_TASK
    },
    --目标任务
    Target = {
        XRedPointConditions.Types.CONDITION_MAIN_NEWPLAYER_TASK
    },
    --特殊商店
    SpecialShop = {
        XRedPointConditions.Types.CONDITION_MAIN_SPECIAL_SHOP
    },
    --新周历
    NewActivityCalendar = {
        XRedPointConditions.Types.CONDITION_NEW_ACTIVITY_CALENDAR_RED
    },
    -- 特殊签到
    SummerSign = {
        XRedPointConditions.Types.CONDITION_SUMMER_SIGNIN_ACTIVITY
    },
    -- 夏日幸运星
    Turntable = {
        XRedPointConditions.Types.CONDITION_TURNTABLE_SUMMARY
    },
    --周挑战
    SignWeeklyChallenge = {
        XRedPointConditions.Types.CONDITION_WEEK_CHALLENGE,
    },
    -- 春节累消
    AccumulateExpend = {
        XRedPointConditions.Types.CONDITION_ACCUMULATE_EXPEND_MAIN,
    }
}

---@param rootUi XUiMain
function XUiMainLeftTop:OnStart(rootUi)
    -- self.Transform = rootUi.PanelLeftTop.gameObject.transform
    self.RootUi = rootUi
    -- XTool.InitUiObject(self)
    self:UpdateInfo()
    --ClickEvent
    self.BtnRoleInfo.CallBack = function() self:OnBtnRoleInfo() end
    self.BtnPassport.CallBack = function() self:OnBtnPassportClick() end

    --Filter
    self:CheckFilterFunctions()

    self.GridActivityButtonDic = {}
    self.ActiveGridActivityButtonDic = {} -- 显示中的活动按钮
    self.ActiveGridActivityCount = 0 -- 显示中的活动按钮数量
    self.WaitForOpenGridActivityCount = 0
    self.WaitForGridActivityButtonDic = {}
end

function XUiMainLeftTop:AfterChangeColorCb()
    if self.InitActivityButtonsFin then
        return
    end
    self:InitActivityButtons()
    self:CheckActivityBtnTimerStart()
    self.InitActivityButtonsFin = true
end

function XUiMainLeftTop:InitActivityButtons()
    -- 单按钮处理
    if self.BtnCalendar then
        self.BtnCalendar.CallBack = function() self:OnBtnCalendar() end
        -- 默认设置为false
        self.BtnCalendar:ShowTag(false)
        self.CalendarRedPoint = self:AddRedPointEvent(self.BtnCalendar, self.CheckNewActivityCalendarRedPoint, self, RedPointConditionGroup.NewActivityCalendar)
    end

    -- 批量按钮处理
    local XUiGridActivityButton = require("XUi/XUiMain/XUiChildItem/XUiGridActivityButton")
    local dataSource = XMVCA.XUiMain:GetActivityBtnListByOrder()
    if XTool.IsTableEmpty(dataSource) then
        return
    end

    local uitheme = self.Transform:GetComponent("XUiTheme")
    XUiHelper.RefreshCustomizedList(self.GridBtnActivity.transform.parent, self.GridBtnActivity.transform, #dataSource, function (i, transform)
        ---@type XUiGridActivityButton
        local grid = self.GridActivityButtonDic[i]
        local config = dataSource[i]
        if not grid then
            grid = XUiGridActivityButton.New(transform, self, config)
            self.GridActivityButtonDic[i] = grid
            grid:InitEvent(function ()
                if grid:CheckShow() then
                    self:AddActiveGridActivityButtonDic(grid)
                end
            end)
        end
        if grid:CheckShow() then
            self:AddActiveGridActivityButtonDic(grid)
        end

        --判断是否是待开发状态的按钮
        if XTool.IsNumberValid(config.TimeId) then
            local endTime = XFunctionManager.GetEndTimeByTimeId(config.TimeId)
            local now = XTime.GetServerNowTimestamp()

            if now < endTime then
                self.WaitForGridActivityButtonDic[grid] = true
                self.WaitForOpenGridActivityCount = self.WaitForOpenGridActivityCount + 1
            end
        end

        local targetItem = transform:Find("Red/Image1"):GetComponent("Image")
        local targetItem2 = transform:Find("Red/Image2"):GetComponent("Image")
        if not targetItem or not targetItem2 then
            return
        end
        uitheme:AddThemeColorsItem(targetItem, 0)
        uitheme:AddThemeColorsItem(targetItem2, 0)
    end)
end

function XUiMainLeftTop:AddActiveGridActivityButtonDic(grid)
    if self.ActiveGridActivityButtonDic[grid] then
        return
    end

    self.ActiveGridActivityButtonDic[grid] = true
    self.ActiveGridActivityCount = self.ActiveGridActivityCount + 1
    self:RemoveWaitForGridActivityButtonDic(grid) --每次激活的时候一定要把wait队列的保底剔除
    self:CheckActivityBtnTimerStart()
end

function XUiMainLeftTop:RemoveActiveGridActivityButtonDic(grid)
    if not self.ActiveGridActivityButtonDic[grid] then
        return
    end

    self.ActiveGridActivityButtonDic[grid] = nil
    self.ActiveGridActivityCount = self.ActiveGridActivityCount - 1
    self:CheckActivityBtnTimerStart()
end

function XUiMainLeftTop:RemoveWaitForGridActivityButtonDic(grid)
    if not self.WaitForGridActivityButtonDic[grid] then
        return
    end

    self.WaitForGridActivityButtonDic[grid] = nil
    self.WaitForOpenGridActivityCount = self.WaitForOpenGridActivityCount - 1
    self:CheckActivityBtnTimerStart()
end

function XUiMainLeftTop:CheckActivityBtnTimerStart()
    if self.ActiveGridActivityCount <= 0 and self.WaitForOpenGridActivityCount <= 0 then
        self:StopActivityButtonsTimer()
    elseif (self.ActiveGridActivityCount > 0 or self.WaitForOpenGridActivityCount > 0) and not self.ActivityButtonDicTimer then
        self:StartActivityButtonsTimer()
    end
end

function XUiMainLeftTop:StartActivityButtonsTimer()
    self.ActivityButtonDicTimer = XScheduleManager.ScheduleForever(function() 
        -- wait列表判断开启
        for grid, v in pairs(self.WaitForGridActivityButtonDic) do
            if grid:CheckShow() then
                self:AddActiveGridActivityButtonDic(grid)
            end
        end

        -- 激活列表判断关闭
        for grid, v in pairs(self.ActiveGridActivityButtonDic) do
            grid:RefreshByTimeUpdate()
            if not grid:CheckShow() then
                self:RemoveActiveGridActivityButtonDic(grid)
            end
        end
       
    end, XScheduleManager.SECOND, 0)
end

function XUiMainLeftTop:StopActivityButtonsTimer()
    if self.ActivityButtonDicTimer then
        XScheduleManager.UnSchedule(self.ActivityButtonDicTimer)
        self.ActivityButtonDicTimer = nil
    end
end

function XUiMainLeftTop:OnEnable()
    --RedPoint
    self:AddRedPointEvent(self.BtnRoleInfo.ReddotObj, self.OnCheckRoleNews, self, RedPointConditionGroup.RoleInfo)
    self:AddRedPointEvent(self.BtnPassport.ReddotObj, self.OnCheckPassportRedPoint, self, RedPointConditionGroup.Passport)
    
    self:StartTimer()
    self:UpdateInfo()
    self:UpdateBtnDlcHunt()
    self:BtnSpecialShopUpdate()
    self:OnPassportOpenStatusUpdate()
    self:OnNewActivityCalendarOpenStatusUpdate()
    -- self:OnSummerSignOpenStatusUpdate()
    -- self:OnAccumulateExpendUpdate()
    self:BtnWeeklyChallengeUpdate()
    self:AddEventListener()
    self:CheckActivityBtnTimerStart()
end

function XUiMainLeftTop:OnDisable()
    --RedPoint
    self:ReleaseRedPoint()
    
    self:StopTimer()
    if self.BtnCalendar then
        self.BtnCalendar:ShowTag(false)
    end
    self:RemoveEventListener()
end

function XUiMainLeftTop:OnDestroy()
    self:StopActivityButtonsTimer()
end

function XUiMainLeftTop:CheckFilterFunctions()
    self.BtnRoleInfo.gameObject:SetActiveEx(not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.Player))
    if self.BtnTarget and (not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.Target) and not XUiManager.IsHideFunc) then
        self.BtnTarget.gameObject:SetActiveEx(XDataCenter.TaskManager.CheckNewbieTaskAvailable())
    end
end

--个人详情入口
function XUiMainLeftTop:OnBtnRoleInfo()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Player) then
        return
    end
    local dict = {}
    dict["ui_first_button"] = XGlobalVar.BtnBuriedSpotTypeLevelOne.BtnUiMainBtnRoleInfo
    dict["role_level"] = XPlayer.GetLevel()
    CS.XRecord.Record(dict, "200004", "UiOpen")
    XLuaUiManager.Open("UiPlayer")
end

--通行证入口
function XUiMainLeftTop:OnBtnPassportClick()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Passport) then
        return
    end
    --活动分包资源检测
    if not XMVCA.XSubPackage:CheckSubpackage() then
        return
    end
    XUiHelper.RecordBuriedSpotTypeLevelOne(XGlobalVar.BtnBuriedSpotTypeLevelOne.BtnUiMainBtnPassport)
    XLuaUiManager.Open("UiPassport")
end

--@region 更新等级经验等
function XUiMainLeftTop:UpdateInfo()
    local curExp = XPlayer.Exp
    local maxExp = XPlayer:GetMaxExp()
    local fillAmount = curExp / maxExp
    self.ImgExpSlider.fillAmount = fillAmount
    -- = (self:GetTheme().Color)

    local name = XPlayer.Name or ""
    self.TxtName.text = name

    local level = XPlayer.GetLevelOrHonorLevel()
    self.TxtLevel.text = level
    self.TxtId.text = XPlayer.Id
    self.Rankt.text = self:GetLevelTxt()
end

function XUiMainLeftTop:GetLevelTxt()
    --self.PanelGlory.gameObject:SetActiveEx(XPlayer.IsHonorLevelOpen())
    if XPlayer.IsHonorLevelOpen() then
        return CS.XTextManager.GetText("HonorLevelShort") .. "/"
    else
        return CS.XTextManager.GetText("HostelDeviceLevel") .. "/"
    end
end

--@endregion
--角色红点
function XUiMainLeftTop:OnCheckRoleNews(count)
    self.BtnRoleInfo:ShowReddot(count >= 0)
end

--通行证红点
function XUiMainLeftTop:OnCheckPassportRedPoint(count)
    self.BtnPassport:ShowReddot(count >= 0)
end

--region   ------------------通行证 start-------------------

function XUiMainLeftTop:UpdatePassportLeftTime()
    local timeId = XMVCA.XPassport:GetPassportActivityTimeId()
    if XFunctionManager.CheckInTimeByTimeId(timeId) then
        self.BtnPassport.gameObject:SetActiveEx(true)
    elseif XMVCA.XPassport:IsActivityClose() then
        self:StopPassportTimer()
        self:OnPassportOpenStatusUpdate()
    else
        self.BtnPassport.gameObject:SetActiveEx(false)
    end
end

function XUiMainLeftTop:StopPassportTimer()
    if self.PassportTimer then
        XScheduleManager.UnSchedule(self.PassportTimer)
        self.PassportTimer = nil
    end
end

function XUiMainLeftTop:OnPassportOpenStatusUpdate()
    if XMVCA.XPassport:IsActivityClose()
            -- 功能未开启时，隐藏通行证按钮
            or not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Passport, false, true)
            or XUiManager.IsHideFunc
    then
        self.BtnPassport.gameObject:SetActiveEx(false)
    else
        self:StopPassportTimer()
        self:UpdatePassportLeftTime()
        self.PassportTimer = XScheduleManager.ScheduleForever(function()
            if self.BtnPassport then
                self:UpdatePassportLeftTime()
            end
        end, XScheduleManager.SECOND, 0)
    end
end

--endregion------------------通行证 finish------------------

--region   ------------------定时器 start-------------------
function XUiMainLeftTop:StartTimer()
end

function XUiMainLeftTop:StopTimer()
    self:StopPassportTimer()
    self:StopRegressionTimer()
    self:StopNewRegressionTimer()
    self:StopRegression3rdTimer()
    self:StopActivityButtonsTimer()
end

--endregion------------------定时器 finish------------------

--region   ------------------事件监听 start-------------------
function XUiMainLeftTop:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_PLAYER_LEVEL_CHANGE, self.UpdateInfo, self)
    XEventManager.AddEventListener(XEventId.EVENT_NOTIFY_PASSPORT_DATA, self.OnPassportOpenStatusUpdate, self)
    XEventManager.AddEventListener(XEventId.EVENT_FUNCTION_EVENT_END, self.OnNewActivityCalendarPlayEffect, self)
    XEventManager.AddEventListener(XEventId.EVENT_NEW_ACTIVITY_CALENDAR_UPDATE, self.OnNewActivityCalendarOpenStatusUpdate, self)
end

function XUiMainLeftTop:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_PLAYER_LEVEL_CHANGE, self.UpdateInfo, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_NOTIFY_PASSPORT_DATA, self.OnPassportOpenStatusUpdate, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FUNCTION_EVENT_END, self.OnNewActivityCalendarPlayEffect, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_NEW_ACTIVITY_CALENDAR_UPDATE, self.OnNewActivityCalendarOpenStatusUpdate, self)
end
--endregion------------------事件监听 finish------------------

--region   ------------------新回归活动 start-------------------

function XUiMainLeftTop:UpdateNewRegressionBtnIcon()
    local state = XDataCenter.NewRegressionManager.GetActivityState()
    local isRegression = state == XNewRegressionConfigs.ActivityState.InRegression
    local nomalIconPath = isRegression and XNewRegressionConfigs.GetChildActivityConfig("MainRegressionNormalIconPath") or XNewRegressionConfigs.GetChildActivityConfig("MainInviteNormalIconPath")
    local pressIconPath = isRegression and XNewRegressionConfigs.GetChildActivityConfig("MainRegressionPressIconPath") or XNewRegressionConfigs.GetChildActivityConfig("MainInvitePressIconPath")
    if self.NewRegressionNormalRawImage then
        self.NewRegressionNormalRawImage:SetRawImage(nomalIconPath)
    end
    if self.NewRegressionPressRawImage then
        self.NewRegressionPressRawImage:SetRawImage(pressIconPath)
    end
end

function XUiMainLeftTop:StopNewRegressionTimer()
    if self.NewRegressionTimer then
        XScheduleManager.UnSchedule(self.NewRegressionTimer)
        self.NewRegressionTimer = nil
    end
end

function XUiMainLeftTop:UpdateNewRegressionLeftTime()
    if not XDataCenter.NewRegressionManager.GetIsOpen() then
        self:StopNewRegressionTimer()
        self.BtnNewRegression.gameObject:SetActiveEx(false)
        return
    end
    if self.TxtNewRegressionLeftTime then
        self.TxtNewRegressionLeftTime.text = XDataCenter.NewRegressionManager.GetLeaveTimeStr(XUiHelper.TimeFormatType.NEW_REGRESSION_ENTRANCE)
    end
end

function XUiMainLeftTop:OnCheckNewRegressionRedPoint(count)
    self.BtnNewRegression:ShowReddot(count >= 0)
end
--endregion------------------新回归活动 finish------------------


--region   ------------------新手任务二期 start-------------------
function XUiMainLeftTop:OnClickNewbieTaskRedPoint(count)
    self.BtnGuide:ShowReddot(count >= 0)
end
--endregion------------------新手任务二期 finish------------------

--region   ------------------DLC start-------------------
function XUiMainLeftTop:UpdateBtnDlcHunt()
    if self.BtnDlcHunt then
        self.BtnDlcHunt.gameObject:SetActiveEx(XDataCenter.DlcHuntManager.IsOpen())
    end
end

function XUiMainLeftTop:OnClickDlcHunt()
    XDataCenter.DlcHuntManager.OpenMain()
end
--endregion------------------DLC finish------------------

--region   ------------------目标 start-------------------
--新手目标入口
function XUiMainLeftTop:OnBtnTarget()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Target) then
        return
    end
    XLuaUiManager.Open("UiNewPlayerTask")
end

--新手目标红点
function XUiMainLeftTop:OnCheckTargetNews(count)
    self.BtnTarget:ShowReddot(count >= 0)
end
--endregion------------------目标 finish------------------

--region   ------------------特殊商店 start-------------------
--- 特殊商店入口点击
function XUiMainLeftTop:OnBtnSpecialShop()
    --活动分包资源检测
    if not XMVCA.XSubPackage:CheckSubpackage() then
        return
    end
    XSaveTool.SaveData(string.format("%d%s", XPlayer.Id, "SpecialShopAlreadyIn"), true)
    
    if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopCommon)
            or XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopActive) then

        local shopId = XSpecialShopConfigs.GetShopId()
        local weaponShopId = XSpecialShopConfigs.GetWeaponFashionShopId()
        XShopManager.GetShopInfo(weaponShopId)
        XShopManager.GetShopInfo(shopId, function()
            XLuaUiManager.Open("UiSpecialFashionShop")
        end)
    end

    XRedPointManager.Check(self.SpecialShopRed)
end

--- 更新特殊商店入口状态
function XUiMainLeftTop:BtnSpecialShopUpdate()
    if self.BtnSpecialShop then
        local isShow = XDataCenter.SpecialShopManager:IsShowEntrance()
        self.BtnSpecialShop.gameObject:SetActiveEx(isShow)
    end
end

-- 特殊商店红点
function XUiMainLeftTop:OnCheckSpecialShopRedPoint(count)
    self.BtnSpecialShop:ShowReddot(count >= 0)
end
--endregion------------------特殊商店 finish------------------

--region   ------------------回归活动 start-------------------

function XUiMainLeftTop:OnBtnRegression()
    --活动分包资源检测
    if not XMVCA.XSubPackage:CheckSubpackage() then
        return
    end
    XLuaUiManager.Open("UiRegression")
end

function XUiMainLeftTop:StopRegressionTimer()
    if self.RegressionTimeSchedule then
        XScheduleManager.UnSchedule(self.RegressionTimeSchedule)
        self.RegressionTimeSchedule = nil
    end
end

--endregion------------------回归活动 finish------------------

--region   ------------------特殊回归活动(3期回归) start-------------------
function XUiMainLeftTop:OnBtnRegression3rdClick()
    XDataCenter.Regression3rdManager.EnterUiMain()
end

function XUiMainLeftTop:OnCheckRegression3rdRedPoint(count)
    self.BtnRegression3rd:ShowReddot(count >= 0)
end

function XUiMainLeftTop:UpdateRegression3rdLeftTime()
    if not XDataCenter.Regression3rdManager.IsOpen() then
        self:StopRegression3rdTimer()
        self.BtnRegression3rd.gameObject:SetActiveEx(false)
        return
    end

    if self.BtnRegression3rd then
        local viewModel = XDataCenter.Regression3rdManager.GetViewModel()
        self.BtnRegression3rd:SetNameByGroup(0, XUiHelper.GetTime(viewModel:GetLeftTime(), XUiHelper.TimeFormatType.ACTIVITY))
    end
end

function XUiMainLeftTop:StopRegression3rdTimer()
    if self.Regression3rdTimer then
        XScheduleManager.UnSchedule(self.Regression3rdTimer)
        self.Regression3rdTimer = nil
    end
end

--endregion------------------特殊回归活动 finish------------------

--region   ------------------新周历 start-------------------

function XUiMainLeftTop:OnBtnCalendar()
    ---@type XNewActivityCalendarAgency
    local calendarAgency = XMVCA:GetAgency(ModuleId.XNewActivityCalendar)
    if not calendarAgency:GetIsOpen() then
        return
    end
    --活动分包资源检测
    if not XMVCA.XSubPackage:CheckSubpackage() then
        return
    end
    XUiHelper.RecordBuriedSpotTypeLevelOne(XGlobalVar.BtnBuriedSpotTypeLevelOne.BtnUiMainBtnCalendar)
    self.RootUi:OnShowCalendar(true)
    -- 设置文本描述
    self.BtnCalendar:SetNameByGroup(0, calendarAgency:GetMainBtnShowTextDesc())
    XRedPointManager.Check(self.CalendarRedPoint)
end

function XUiMainLeftTop:OnNewActivityCalendarOpenStatusUpdate()
    ---@type XNewActivityCalendarAgency
    local calendarAgency = XMVCA:GetAgency(ModuleId.XNewActivityCalendar)
    local isOpen = calendarAgency:GetIsOpen(true)
    self.BtnCalendar.gameObject:SetActiveEx(isOpen)
    if not isOpen then
        return
    end
    -- 设置文本描述
    self.BtnCalendar:SetNameByGroup(0, calendarAgency:GetMainBtnShowTextDesc())
end

function XUiMainLeftTop:CheckNewActivityCalendarRedPoint(count)
    local isShowRedPoint = count >= 0
    self.BtnCalendar:ShowReddot(isShowRedPoint)
    self.NormalImgBell2.gameObject:SetActiveEx(isShowRedPoint)
    self.PressImgBell2.gameObject:SetActiveEx(isShowRedPoint)
    self.NormalImgBell.gameObject:SetActiveEx(not isShowRedPoint)
    self.PressImgBell.gameObject:SetActiveEx(not isShowRedPoint)
end

-- 检查是否播放特效
function XUiMainLeftTop:OnNewActivityCalendarPlayEffect()
    ---@type XNewActivityCalendarAgency
    local calendarAgency = XMVCA:GetAgency(ModuleId.XNewActivityCalendar)
    local isOpen = calendarAgency:GetIsOpen(true)
    if not isOpen then
        return
    end
    if self.RootUi:IsShowCalendar() or self.RootUi:IsShowTerminal() then
        return
    end
    local isPlayEffect = calendarAgency:CheckIsNeedPlayEffect()
    self.BtnCalendar:ShowTag(isPlayEffect)
end

--endregion------------------新周历 finish------------------

--region   ------------------夏日签到 start-------------------

function XUiMainLeftTop:OnBtnSummerSignClick()
    XDataCenter.SummerSignInManager.OnOpenMain()
end

function XUiMainLeftTop:CheckSummerSignRedPoint(count)
    self.BtnSummerSign3:ShowReddot(count >= 0)
end

function XUiMainLeftTop:GetSummerSignIsOpen()
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.SummerSignIn) then
        return false
    end
    return XDataCenter.SummerSignInManager.IsOpen()
end

function XUiMainLeftTop:OnSummerSignOpenStatusUpdate()
    local isOpen = self:GetSummerSignIsOpen()
    if self.BtnSummerSign3 then
        self.BtnSummerSign3.gameObject:SetActiveEx(isOpen)
        if isOpen then
            XRedPointManager.Check(self.SummerSignRedPoint)
        end
    end
end

--endregion------------------夏日签到 finish-------------------

--region   ------------------大转盘 start-------------------

function XUiMainLeftTop:OnBtnTurntableClick()
    --活动分包资源检测
    if not XMVCA.XSubPackage:CheckSubpackage() then
        return
    end
    XLuaUiManager.Open("UiTurntableMain")
end

function XUiMainLeftTop:CheckTurntableRedPoint(count)
    self.BtnTurntable:ShowReddot(count >= 0)
end

--endregion------------------大转盘 finish-------------------

-- region v2.11春节累消

function XUiMainLeftTop:CheckAccumulateRedPoint(count)
    self.BtnAccumulateDraw:ShowReddot(count >= 0)
end

-- endregion

--region --------------------2.11 春节周挑战-----------------------
function XUiMainLeftTop:BtnWeeklyChallengeUpdate()
    if self.BtnSignWeeklyChallenge then
        local isOpen=XDataCenter.WeekChallengeManager.IsOpen()
        self.BtnSignWeeklyChallenge.gameObject:SetActiveEx(isOpen)
        if  isOpen then
            XRedPointManager.Check(self.SignWeeklyChallengeRedPoint)
            return
        end
    end
end

function XUiMainLeftTop:CheckWeeklyChallengeRedPoint(count)
    self.BtnSignWeeklyChallenge:ShowReddot(count >= 0)
end
--endregion --------------------------------------------

return XUiMainLeftTop