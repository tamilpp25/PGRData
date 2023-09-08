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
    --RedPoint
    self:AddRedPointEvent(self.BtnRoleInfo.ReddotObj, self.OnCheckRoleNews, self, RedPointConditionGroup.RoleInfo)

    self:AddRedPointEvent(self.BtnPassport.ReddotObj, self.OnCheckPassportRedPoint, self, RedPointConditionGroup.Passport)

    --Filter
    self:CheckFilterFunctions()

    self:InitActivityButton()
end

function XUiMainLeftTop:InitActivityButton()
    self.PanelActivityBtn.gameObject:SetActiveEx(not XUiManager.IsHideFunc)
    if self.BtnNewRegression then
        self.BtnNewRegression.CallBack = function() XDataCenter.NewRegressionManager.OpenMainUi() end
        self:AddRedPointEvent(self.BtnNewRegression.ReddotObj, self.OnCheckNewRegressionRedPoint, self, RedPointConditionGroup.NewRegression)
    end

    if self.BtnGuide then
        self.BtnGuide.CallBack = function()
            XDataCenter.NewbieTaskManager.OpenMainUi()
        end
        self:AddRedPointEvent(self.BtnGuide.ReddotObj, self.OnClickNewbieTaskRedPoint, self, RedPointConditionGroup.Guide)
    end

    if self.BtnDlcHunt then
        XUiHelper.RegisterClickEvent(self, self.BtnDlcHunt, self.OnClickDlcHunt)
    end

    if self.BtnTarget then
        self.BtnTarget.CallBack = function() self:OnBtnTarget() end
        self:AddRedPointEvent(self.BtnTarget.ReddotObj, self.OnCheckTargetNews, self, RedPointConditionGroup.Target)
    end

    if self.BtnSpecialShop then
        self.BtnSpecialShop.CallBack = function() self:OnBtnSpecialShop() end
        self.SpecialShopRed = self:AddRedPointEvent(self.BtnSpecialShop.ReddotObj, self.OnCheckSpecialShopRedPoint, self, RedPointConditionGroup.SpecialShop)
    end

    if self.BtnRegression then
        self.BtnRegression.CallBack = function() self:OnBtnRegression() end
        self:AddRedPointEvent(self.BtnRegression.ReddotObj, nil, self, RedPointConditionGroup.Regression)
    end

    if self.BtnRegression3rd then
        self.BtnRegression3rd.gameObject:SetActiveEx(false)
        self.BtnRegression3rd.CallBack = function() self:OnBtnRegression3rdClick() end
        self:AddRedPointEvent(self.BtnRegression3rd, self.OnCheckRegression3rdRedPoint, self, RedPointConditionGroup.NewRegression3rd)
    end

    if self.BtnKujiequ then
        self.BtnKujiequ.CallBack = function() self:OnClickBtnKujiequ() end
    end

    if self.BtnCalendar then
        self.BtnCalendar.CallBack = function() self:OnBtnCalendar() end
        -- 默认设置为false
        self.BtnCalendar:ShowTag(false)
        self.CalendarRedPoint = self:AddRedPointEvent(self.BtnCalendar, self.CheckNewActivityCalendarRedPoint, self, RedPointConditionGroup.NewActivityCalendar)
    end

    if self.BtnSummerSign3 then
        self.BtnSummerSign3.CallBack = function() self:OnBtnSummerSignClick() end
        self.SummerSignRedPoint = self:AddRedPointEvent(self.BtnSummerSign3, self.CheckSummerSignRedPoint, self, RedPointConditionGroup.SummerSign)
    end

    if self.BtnTurntable then
        self.BtnTurntable.CallBack = function() self:OnBtnTurntableClick() end
        self.TurntableRedPoint = self:AddRedPointEvent(self.BtnTurntable, self.CheckTurntableRedPoint, self, RedPointConditionGroup.Turntable)
    end
    --TODO 后续新增入口时，注意分包资源检测
end

function XUiMainLeftTop:OnEnable()
    self:StartTimer()
    self:UpdateInfo()
    self:UpdateBtnDlcHunt()
    self:BtnSpecialShopUpdate()
    self:OnPassportOpenStatusUpdate()
    self:OnNewRegressionOpenStatusUpdate()
    self:OnRegressionOpenStatusUpdate()
    self:OnNewbieTaskOpenStatusUpdate()
    self:OnRegression3rdOpenStatusUpdate()
    self:OnNewActivityCalendarOpenStatusUpdate()
    self:BtnKujiequUpdate()
    self:OnSummerSignOpenStatusUpdate()
    self:OnTurntableOpenStateUpdate()

    self:AddEventListener()
end

function XUiMainLeftTop:OnDisable()
    self:StopTimer()
    if self.BtnCalendar then
        self.BtnCalendar:ShowTag(false)
    end
    self:RemoveEventListener()

end

function XUiMainLeftTop:OnDestroy()
    
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
    self.PanelGlory.gameObject:SetActiveEx(XPlayer.IsHonorLevelOpen())
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
end

--endregion------------------定时器 finish------------------

--region   ------------------事件监听 start-------------------
function XUiMainLeftTop:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_PLAYER_LEVEL_CHANGE, self.UpdateInfo, self)
    XEventManager.AddEventListener(XEventId.EVENT_NOTIFY_PASSPORT_DATA, self.OnPassportOpenStatusUpdate, self)
    XEventManager.AddEventListener(XEventId.EVENT_REGRESSION_OPEN_STATUS_UPDATE, self.OnRegressionOpenStatusUpdate, self)
    XEventManager.AddEventListener(XEventId.EVENT_NEW_REGRESSION_OPEN_STATUS_UPDATE, self.OnNewRegressionOpenStatusUpdate, self)
    XEventManager.AddEventListener(XEventId.EVENT_REGRESSION3_ACTIVITY_STATUS_CHANGE, self.OnRegression3rdOpenStatusUpdate, self)
    XEventManager.AddEventListener(XEventId.EVENT_FUNCTION_EVENT_END, self.OnNewActivityCalendarPlayEffect, self)
    XEventManager.AddEventListener(XEventId.EVENT_NEW_ACTIVITY_CALENDAR_UPDATE, self.OnNewActivityCalendarOpenStatusUpdate, self)
    XEventManager.AddEventListener(XEventId.EVENT_TURNTABLE_PROGRESS_REWARD, self.OnTurntableOpenStateUpdate, self)
end

function XUiMainLeftTop:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_PLAYER_LEVEL_CHANGE, self.UpdateInfo, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_NOTIFY_PASSPORT_DATA, self.OnPassportOpenStatusUpdate, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_REGRESSION_OPEN_STATUS_UPDATE, self.OnRegressionOpenStatusUpdate, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_NEW_REGRESSION_OPEN_STATUS_UPDATE, self.OnNewRegressionOpenStatusUpdate, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_REGRESSION3_ACTIVITY_STATUS_CHANGE, self.OnRegression3rdOpenStatusUpdate, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FUNCTION_EVENT_END, self.OnNewActivityCalendarPlayEffect, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_NEW_ACTIVITY_CALENDAR_UPDATE, self.OnNewActivityCalendarOpenStatusUpdate, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_TURNTABLE_PROGRESS_REWARD, self.OnTurntableOpenStateUpdate, self)
end
--endregion------------------事件监听 finish------------------

--region   ------------------新回归活动 start-------------------
function XUiMainLeftTop:OnNewRegressionOpenStatusUpdate()
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
        XRedPointManager.CheckOnceByButton(self.BtnNewRegression, RedPointConditionGroup.NewRegression)
    end
end

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
function XUiMainLeftTop:OnNewbieTaskOpenStatusUpdate()
    local isOpen = XDataCenter.NewbieTaskManager.GetIsOpen()
    self.BtnGuide.gameObject:SetActiveEx(isOpen)
    if isOpen then
        XRedPointManager.CheckOnceByButton(self.BtnGuide, RedPointConditionGroup.Guide)
    end
end

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

--function XUiMainLeftTop:UpdateMusicPlayerText()
--    local albumId = XDataCenter.MusicPlayerManager.GetUiMainNeedPlayedAlbumId()
--    local template = XMusicPlayerConfigs.GetAlbumTemplateById(albumId)
--    if not template then return end
--    self.MaskMusicPlayer.gameObject:SetActiveEx(true)
--    self.TxtMusicName.text = template.Name
--
--    local txtDescWidth = XUiHelper.CalcTextWidth(self.TxtMusicDesc)
--    local txtNameWidth = XUiHelper.CalcTextWidth(self.TxtMusicName)
--    local txtWidth = txtDescWidth + txtNameWidth
--    local maskWidth = self.MaskMusicPlayer.sizeDelta.x
--    local txtDescTransform = self.TxtMusicDesc.transform
--    local txtLocalPosition = txtDescTransform.localPosition
--    txtDescTransform.localPosition = Vector3(maskWidth, txtLocalPosition.y, txtLocalPosition.z)
--    local distance = txtWidth + maskWidth
--    local sequence = DOTween.Sequence()
--    self.TweenSequenceTxtMusicPlayer = sequence
--    sequence:Append(txtDescTransform:DOLocalMoveX(-txtWidth, distance / MusicPlayerTextMoveSpeed))
--    sequence:AppendInterval(MusicPlayerTextMovePauseInterval)
--    sequence:SetLoops(-1)
--end

--region   ------------------目标 start-------------------
--新手目标入口
function XUiMainLeftTop:OnBtnTarget()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Target) then
        return
    end
    ----活动分包资源检测
    --if not XMVCA.XSubPackage:CheckSubpackage() then
    --    return
    --end
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
function XUiMainLeftTop:OnRegressionOpenStatusUpdate()
    local isOpen = XDataCenter.RegressionManager.IsHaveOneRegressionActivityOpen()
    self.BtnRegression.gameObject:SetActiveEx(isOpen)
    if not isOpen and self.RegressionTimeSchedule then
        XScheduleManager.UnSchedule(self.RegressionTimeSchedule)
        self.RegressionTimeSchedule = nil
        self.TxtRegressionLeftTime.gameObject:SetActiveEx(false)
    end
end

function XUiMainLeftTop:OnBtnRegression()
    --活动分包资源检测
    if not XMVCA.XSubPackage:CheckSubpackage() then
        return
    end
    XLuaUiManager.Open("UiRegression")
end

function XUiMainLeftTop:UpdateRegressionLeftTime()
    local targetTime = XDataCenter.RegressionManager.GetTaskEndTime()
    if not targetTime then
        if self.RegressionTimeSchedule then
            XScheduleManager.UnSchedule(self.RegressionTimeSchedule)
            self.RegressionTimeSchedule = nil
        end
        self.TxtRegressionLeftTime.gameObject:SetActiveEx(false)
        return
    end
    local leftTime = targetTime - XTime.GetServerNowTimestamp()
    if leftTime > 0 then
        self.TxtRegressionLeftTime.text = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.MAINBATTERY)
        self.TxtRegressionLeftTime.gameObject:SetActiveEx(true)
    elseif self.RegressionTimeSchedule then
        self.TxtRegressionLeftTime.gameObject:SetActiveEx(false)
        if self.RegressionTimeSchedule then
            XScheduleManager.UnSchedule(self.RegressionTimeSchedule)
        end
        self.RegressionTimeSchedule = nil
    end
end

function XUiMainLeftTop:RefreshRegressionTime()
    if XDataCenter.RegressionManager.IsHaveOneRegressionActivityOpen() then
        self:UpdateRegressionLeftTime()
        if not self.RegressionTimeSchedule then
            self.RegressionTimeSchedule = XScheduleManager.ScheduleForever(function()
                self:UpdateRegressionLeftTime()
            end, RegressionMainViewFreshTimeInterval * XScheduleManager.SECOND)
        end
    else
        self.TxtRegressionLeftTime.gameObject:SetActiveEx(false)
    end
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

function XUiMainLeftTop:OnRegression3rdOpenStatusUpdate()
    local isOpen = XDataCenter.Regression3rdManager.IsOpen()
    self.BtnRegression3rd.gameObject:SetActiveEx(isOpen)
    if not isOpen then
        return
    end
    self:UpdateRegression3rdLeftTime()

    if not self.Regression3rdTimer then
        self.Regression3rdTimer = XScheduleManager.ScheduleForever(function()
            self:UpdateRegression3rdLeftTime()
        end, XScheduleManager.SECOND)
    end

    XRedPointManager.CheckOnceByButton(self.BtnRegression3rd, RedPointConditionGroup.NewRegression3rd)
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



--region   ------------------库街区 start-------------------
-- 库街区按钮点击响应
function XUiMainLeftTop:OnClickBtnKujiequ()
    XUiHelper.RecordBuriedSpotTypeLevelOne(XGlobalVar.BtnBuriedSpotTypeLevelOne.BtnUiMainBtnKuJieQu)
    XDataCenter.KujiequManager.OpenKujiequ()
end

-- 库街区按钮入口刷新
function XUiMainLeftTop:BtnKujiequUpdate()
    if self.BtnKujiequ then
        local isShow = XDataCenter.KujiequManager:IsShowEntrance()
        self.BtnKujiequ.gameObject:SetActiveEx(isShow)
    end
end

--endregion------------------库街区 finish------------------

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

function XUiMainLeftTop:OnTurntableOpenStateUpdate()
    local isOpen
    if XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Turntable) then
        ---@type XTurntableAgency
        local agency = XMVCA:GetAgency(ModuleId.XTurntable)
        isOpen = agency:IsOpen()
    else
        isOpen = false
    end
    if self.BtnTurntable then
        self.BtnTurntable.gameObject:SetActiveEx(isOpen)
        if isOpen then
            XRedPointManager.Check(self.TurntableRedPoint)
        end
    end
end

function XUiMainLeftTop:CheckTurntableRedPoint(count)
    self.BtnTurntable:ShowReddot(count >= 0)
end

--endregion------------------大转盘 finish-------------------

return XUiMainLeftTop