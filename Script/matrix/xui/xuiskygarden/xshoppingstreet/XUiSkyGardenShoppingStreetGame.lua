local XUiSkyGardenShoppingStreetTargetGridTarget = require("XUi/XUiSkyGarden/XShoppingStreet/Grid/XUiSkyGardenShoppingStreetTargetGridTarget")
local XUiSkyGardenShoppingStreetGameTargetDot = require("XUi/XUiSkyGarden/XShoppingStreet/Grid/XUiSkyGardenShoppingStreetGameTargetDot")
local XUiSkyGardenShoppingStreetGameBuildingArea = require("XUi/XUiSkyGarden/XShoppingStreet/Component/XUiSkyGardenShoppingStreetGameBuildingArea")
local XUiSkyGardenShoppingStreetAsset = require("XUi/XUiSkyGarden/XShoppingStreet/Component/XUiSkyGardenShoppingStreetAsset")
local XUiSkyGardenShoppingStreetGameCustomer = require("XUi/XUiSkyGarden/XShoppingStreet/Component/XUiSkyGardenShoppingStreetGameCustomer")
local XUiSkyGardenShoppingStreetGamePet = require("XUi/XUiSkyGarden/XShoppingStreet/Component/XUiSkyGardenShoppingStreetGamePet")

---@class XUiSkyGardenShoppingStreetGame : XLuaUi
---@field PanelTop UnityEngine.RectTransform
---@field BtnLeave XUiComponent.XUiButton
---@field BtnNews XUiComponent.XUiButton
---@field BtnSettlement XUiComponent.XUiButton
---@field BtnLight XUiComponent.XUiButton
---@field BtnStart XUiComponent.XUiButton
---@field BtnChooseCelebration XUiComponent.XUiButton
---@field TxtNum UnityEngine.UI.Text
---@field PanelPet UnityEngine.RectTransform
---@field ImgPet UnityEngine.UI.Image
---@field PanelTalk UnityEngine.RectTransform
---@field TxtTalk UnityEngine.UI.Text
---@field BtnTarget XUiComponent.XUiButton
---@field ListTarget UnityEngine.RectTransform
---@field GridTarget UnityEngine.RectTransform
---@field PanelBuild UnityEngine.RectTransform
---@field PanelOperate UnityEngine.RectTransform
---@field BuildingArea UnityEngine.RectTransform
local XUiSkyGardenShoppingStreetGame = XMVCA.XBigWorldUI:Register(nil, "UiSkyGardenShoppingStreetGame")

--region 生命周期
function XUiSkyGardenShoppingStreetGame:OnAwake()
    self._TaskGridDotUi = {}
    self._HeadUiCache = {}
    self._TimerIdList = {}
    self._CustomerHeadList = {}
    ---@type XUiSkyGardenShoppingStreetTargetGridTarget
    self._TargetList = {}
    ---@type XUiSkyGardenShoppingStreetGameBuildingArea
    self.BuildingAreaUi = XUiSkyGardenShoppingStreetGameBuildingArea.New(self.BuildingArea, self)
    ---@type XUiSkyGardenShoppingStreetAsset
    self.PanelTopUi = XUiSkyGardenShoppingStreetAsset.New(self.PanelTop, self)
    ---@type XUiSkyGardenShoppingStreetGamePet
    self.PanelPetUi = XUiSkyGardenShoppingStreetGamePet.New(self.PanelPet, self)
    self.PanelPetUi:Close()
    self:_RegisterButtonClicks()

    self.CustomerWaitFinishNextTask = handler(self, self._CustomerWaitFinishNextTask)
    self.CustomerWaitFinishDestroy = handler(self, self._CustomerWaitFinishDestroy)
    self.GameUpdateTimer = handler(self, self._UpdateTimer)

    self._CurrentGameState = 0
    self._GameStateType = {
        None = 0,
        _CheckLimitTask = 1,
        _CheckStageFinish = 2,
        _CheckShowSale = 3,
        _ShowMascotMessage = 4,
    }
    self._GameStatusFunc = {
        [self._GameStateType._CheckLimitTask] = self._CheckLimitTask,
        [self._GameStateType._CheckStageFinish] = self._CheckStageFinish,
        [self._GameStateType._CheckShowSale] = self._CheckShowSale,
        [self._GameStateType._ShowMascotMessage] = self._ShowMascotMessage,
    }
    -- local X3C_CMD = CS.X3CCommand
    -- XMVCA.X3CProxy:RegisterHandler(X3C_CMD.CMD_SHOPSTREET_REQUEST_GAMEPLAY_DATA, XMVCA.XSkyGardenShoppingStreet.X3CSgRequestData, XMVCA.XSkyGardenShoppingStreet)
    -- XMVCA.X3CProxy:RegisterHandler(X3C_CMD.CMD_SHOPSTREET_CUSTOMER_FINISH_TASK, XMVCA.XSkyGardenShoppingStreet.X3CSgCustomerFinishTask, XMVCA.XSkyGardenShoppingStreet)
    if self.BtnEndRound then
        self.BtnEndRound.gameObject:SetActive(false)
    end
end

function XUiSkyGardenShoppingStreetGame:OnStart(...)
    self._Control:SgStreetStageEnterRequest()

    self.ListTarget.gameObject:SetActive(false)
    self.Customer.gameObject:SetActive(false)

    local stageId = self._Control:GetCurrentStageId()
    local stageCfg = self._Control:GetStageConfigsByStageId(stageId)
    self.BtnNews.gameObject:SetActive(stageCfg.NewsTypeGroup ~= 0 and stageCfg.GrapevineGroup ~= 0)
    self.BtnLight.gameObject:SetActive(stageCfg.BillboardGroup ~= 0)

    self._SpeedList = {}
    -- local gameSpeedChoice = tonumber(self._Control:GetGlobalConfigByKey("GameSpeedChoice"))
    for i = 1, 3 do
        self._SpeedList[i] = tonumber(self._Control:GetGlobalConfigByKey("GameSpeed" .. i))
    end

    XMVCA.XSkyGardenShoppingStreet:X3CSetCustomerFinishTaskCallback(handler(self, self._CustomerMoveFinish))

    if self._Control:TryStartAutoRunRound() then
        self:_StartGame()
    else
        self:_ShowEdit()
    end
end

function XUiSkyGardenShoppingStreetGame:OnEnable()
    self._Control:X3CSetVirtualCameraByCameraIndex(2)
    if self._StartGameStatus then
        self:_RegisterSchedules()
        self:_ResumeRun()
    else
        self:_RefreshGameInfo()
    end
    local checkFunc = self._GameStatusFunc[self._CurrentGameState]
    if checkFunc then
        self._CurrentGameState = self._GameStateType.None
        checkFunc(self)
    end
end

function XUiSkyGardenShoppingStreetGame:OnGetLuaEvents()
    return {
        XMVCA.XBigWorldService.DlcEventId.EVENT_BUSINESS_STREET_FINISH_TASK_REFRESH,
        XMVCA.XBigWorldService.DlcEventId.EVENT_BUSINESS_STREET_BUFF_REFRESH,
    }
end

function XUiSkyGardenShoppingStreetGame:OnNotify(event)
    if event == XMVCA.XBigWorldService.DlcEventId.EVENT_BUSINESS_STREET_FINISH_TASK_REFRESH then
        self:_RefreshTargetInfo()
    elseif event == XMVCA.XBigWorldService.DlcEventId.EVENT_BUSINESS_STREET_BUFF_REFRESH then
        self:_RefreshLimitTaskInfo()
    end
end

function XUiSkyGardenShoppingStreetGame:OnDisable()
    self:_RemoveAllTimer()
    if self._StartGameStatus then
        self:_StopRun()
    end
end

function XUiSkyGardenShoppingStreetGame:OnDestroy()
    self:_ResetAllRunData()
    XMVCA.XSkyGardenShoppingStreet:X3CSetCustomerFinishTaskCallback()
    self._Control:X3CSetStageStatus(XMVCA.XSkyGardenShoppingStreet.X3CStageStatus.Normal)
end

-- --- 添加单次定时器
-- ---@param func function 回调函数
-- ---@param delay number 延迟时间，单位毫秒
-- ---@return number timerId 定时器ID
-- function XUiSkyGardenShoppingStreetGame:_AddTimerOnce(func, delay)
--     local timerId = XScheduleManager.ScheduleOnce(func, delay)
--     self._TimerIdList[timerId] = timerId
--     return timerId
-- end

--- 添加循环定时器
---@param func function 回调函数
---@param interval number 间隔时间，单位毫秒
---@param delay number 延迟时间，单位毫秒
---@return number timerId 定时器ID
function XUiSkyGardenShoppingStreetGame:_AddTimerForever(func, interval, delay)
    local timerId = XScheduleManager.ScheduleForever(func, interval, delay)
    self._TimerIdList[timerId] = timerId
    return timerId
end

-- -- 移除定时器
-- ---@param timerId number 定时器ID
-- function XUiSkyGardenShoppingStreetGame:_RemoveTimer(timerId)
--     if not self._TimerIdList[timerId] then return end
--     XScheduleManager.UnSchedule(timerId)
--     self._TimerIdList[timerId] = nil
-- end

function XUiSkyGardenShoppingStreetGame:_RemoveAllTimer()
    for timerId, _ in pairs(self._TimerIdList) do
        XScheduleManager.UnSchedule(timerId)
    end
    self._TimerIdList = {}
    self._TimerId = nil
end
--endregion

function XUiSkyGardenShoppingStreetGame:_RefreshLimitTaskInfo()
    local limitTask = self._Control:GetLimitTask()
    if not limitTask then
        self.PanelTask.gameObject:SetActive(false)
        return
    end
    local XSgStreetTaskState = XMVCA.XSkyGardenShoppingStreet.XSgStreetTaskState
    local isFinshLimitTask = limitTask.State ~= XSgStreetTaskState.Activated
    self.PanelTask.gameObject:SetActive(not isFinshLimitTask)

    if not isFinshLimitTask then
        local taskCfg = self._Control:GetStageTaskConfigsById(limitTask.ConfigId)
        local scheduleDiv = taskCfg.ScheduleDiv
        if not scheduleDiv or scheduleDiv == 0 then
            scheduleDiv = 1
        end
        self.TxtDetail.text = string.format(taskCfg.ConditionSampleDesc, XTool.MathGetRoundingValueStandard(limitTask.Schedule / scheduleDiv, 1) .. "/" .. XTool.MathGetRoundingValueStandard(taskCfg.Schedule / scheduleDiv, 1))
        self.TxtRound.text = XMVCA.XBigWorldService:GetText("SG_SS_LeftRoundText", self._Control:GetBillboardLeftTurn())
    end
end

function XUiSkyGardenShoppingStreetGame:_RefreshTargetInfo()
    if self.BtnTarget.gameObject.activeInHierarchy then
        local stageId = self._Control:GetCurrentStageId()
        local stageCfg = self._Control:GetStageConfigsByStageId(stageId)
        XTool.UpdateDynamicItem(self._TaskGridDotUi, stageCfg.TargetTaskIds, self.GridDot, XUiSkyGardenShoppingStreetGameTargetDot, self)
    end
end

function XUiSkyGardenShoppingStreetGame:_RefreshGameInfo()
    self._RoundNum = self._Control:GetRunRound()
    self.TxtNum.text = XMVCA.XBigWorldService:GetText("SG_SS_RoundText", self._RoundNum)

    local hasLimitTask = self._Control:HasStageLimitTask()
    local hasSale = self._Control:HasPromotion()
    self.BtnChooseLight.gameObject:SetActive(hasLimitTask)
    self.BtnChooseCelebration.gameObject:SetActive(hasSale and not hasLimitTask)
    self.BtnStart.gameObject:SetActive(not hasSale and not hasLimitTask)

    self:_RefreshTargetInfo()

    self.PanelPetUi:CheckTips()

    self:_RefreshLimitTaskInfo()
end

--region 按钮事件
function XUiSkyGardenShoppingStreetGame:OnBtnLeaveClick()
    self:Close()
end

function XUiSkyGardenShoppingStreetGame:OnBtnNewsClick()
    local newsList = self._Control:GetStageNews()
    local grapvinesList = self._Control:GetStageGrapevines()
    if table.nums(newsList) > 0 or table.nums(grapvinesList) > 0 then
        XMVCA.XBigWorldUI:Open("UiSkyGardenShoppingStreetPopupNewsLogs")
    else
        XMVCA.XSkyGardenShoppingStreet:Toast(XMVCA.XBigWorldService:GetText("SG_SS_NotNewTips"))
    end
end

function XUiSkyGardenShoppingStreetGame:OnBtnSettlementClick()
    local settleData = self._Control:GetSettleResultData()
    if settleData then
        XMVCA.XBigWorldUI:Open("UiSkyGardenShoppingStreetPopupRoundEnd")
    else
        XMVCA.XSkyGardenShoppingStreet:Toast(XMVCA.XBigWorldService:GetText("SG_SS_NotYesterdayData"))
    end
end

function XUiSkyGardenShoppingStreetGame:OnBtnLightClick()
    XMVCA.XBigWorldUI:Open("UiSkyGardenShoppingStreetLight")
end

function XUiSkyGardenShoppingStreetGame:OnBtnStartClick()
    self._Control:StartRunRound(function()
        self:_StartGame()
    end)
end

function XUiSkyGardenShoppingStreetGame:OnBtnChooseSaleClick()
    XMVCA.XBigWorldUI:Open("UiSkyGardenShoppingStreetSale")
end

function XUiSkyGardenShoppingStreetGame:OnBtnTargetClick()
    self.ListTarget.gameObject:SetActive(true)
    local stageId = self._Control:GetCurrentStageId()
    local config = self._Control:GetStageConfigsByStageId(stageId)
    XTool.UpdateDynamicItem(self._TargetList, config.TargetTaskIds, self.GridTarget, XUiSkyGardenShoppingStreetTargetGridTarget, self)
    XUiManager.CreateBlankArea2Close(self.ListTarget.gameObject, function ()
        XTool.UpdateDynamicItem(self._TargetList)
    end)
end

function XUiSkyGardenShoppingStreetGame:OnBtnEndRoundClick()
    -- 兼容快速跳过代码，服务器检查
    for _customerId, customerData in pairs(self._CustomerDataList) do
        while not customerData:IsFinishAllTask() do
            local taskData = customerData:GetCurrentTask()
            self._Control:ClientAddResourceByAwardGold(taskData.ShopAwardGold)
            customerData:FinishCurrentTask()
        end
    end

    self._Control:EndRunRound(function()
        self:_EndGame()
    end)
end

function XUiSkyGardenShoppingStreetGame:OnBtnPlayClick()
    if self._IsStop then
        self:_ResumeRun()
    else
        self:_StopRun()
    end
end

function XUiSkyGardenShoppingStreetGame:OnBtnSpeedClick()
    self:_SetTimeScaleByScaleIndex(self._SpeedIndex + 1)
end

-- 设置时间缩放
function XUiSkyGardenShoppingStreetGame:_SetTimeScale(timescale, notCache)
    local setTimeScale = timescale or 1
    if not notCache then
        self._TimeScale = setTimeScale
    end
    local lastStop = self._IsStop
    self._IsStop = setTimeScale == 0
    self.BtnPlayNormal.gameObject:SetActive(not self._IsStop)
    self.BtnPlaySelect.gameObject:SetActive(self._IsStop)
    self._Control:X3CSetGameSpeed(setTimeScale)
    if lastStop ~= self._IsStop then
        for _, uiNode in pairs(self._CustomerHeadList) do
            uiNode:SetUpdateStatus(not self._IsStop)
        end
    end
end

--- 设置时间缩放通过索引
---@param index number 索引
---@param isForce boolean 是否强制设置
function XUiSkyGardenShoppingStreetGame:_SetTimeScaleByScaleIndex(index, isForce)
    if index > #self._SpeedList then
        index = 1
    end
    if index == self._SpeedIndex and not isForce then return end

    if self._SpeedIndex then
        self.BtnSpeed.transform:GetChild(self._SpeedIndex - 1).gameObject:SetActive(false)
    end
    self._SpeedIndex = index
    self.BtnSpeed.transform:GetChild(self._SpeedIndex - 1).gameObject:SetActive(true)
    self:_SetTimeScale(self._SpeedList[self._SpeedIndex])
    self._Control:SetGameSpeedIndex(self._SpeedIndex)
end

-- 暂停运行
function XUiSkyGardenShoppingStreetGame:_StopRun()
    self:_SetTimeScale(0, true)
end

-- 恢复运行
function XUiSkyGardenShoppingStreetGame:_ResumeRun()
    self:_SetTimeScaleByScaleIndex(self._SpeedIndex, true)
end
--endregion

--region 私有方法
function XUiSkyGardenShoppingStreetGame:_RegisterButtonClicks()
    --在此处注册按钮事件
    self.BtnLeave.CallBack = function() self:OnBtnLeaveClick() end
    self.BtnNews.CallBack = function() self:OnBtnNewsClick() end
    self.BtnSettlement.CallBack = function() self:OnBtnSettlementClick() end
    self.BtnLight.CallBack = function() self:OnBtnLightClick() end
    self.BtnStart.CallBack = function() self:OnBtnStartClick() end
    self.BtnChooseLight.CallBack = function() self:OnBtnLightClick() end
    self.BtnChooseCelebration.CallBack = function() self:OnBtnChooseSaleClick() end
    self.BtnTarget.CallBack = function() self:OnBtnTargetClick() end
    self.BtnEndRound.CallBack = function() self:OnBtnEndRoundClick() end
    self.BtnPlay.CallBack = function() self:OnBtnPlayClick() end
    self.BtnSpeed.CallBack = function() self:OnBtnSpeedClick() end
end

function XUiSkyGardenShoppingStreetGame:_ShowEdit()
    self._Control:SetEndRunRoundState()
    self._StartGameStatus = false
    self.BtnTarget.gameObject:SetActive(true)
    self.PanelBuild.gameObject:SetActive(true)
    self.PanelOperate.gameObject:SetActive(false)
    self.BtnSettlement.gameObject:SetActive(self._Control:GetRunRound() > 1)
    local showMidPanelBtn = self.BtnSettlement.gameObject.activeSelf or self.BtnLight.gameObject.activeSelf or self.BtnNews.gameObject.activeSelf
    self.PanelMiddleBtn.gameObject:SetActive(showMidPanelBtn)
    self.BuildingAreaUi:SetEditMode(true)
    self:_RefreshGameInfo()
    self._Control:X3CSetStageStatus(XMVCA.XSkyGardenShoppingStreet.X3CStageStatus.Edit)

    self:_ShowNews()
end

--region 运营逻辑
function XUiSkyGardenShoppingStreetGame:_RegisterSchedules()
    if self._TimerId then return end

    self._TimerGap = 100
    --在此处注册定时器
    self._TimerId = self:_AddTimerForever(self.GameUpdateTimer, self._TimerGap, 0)
end

function XUiSkyGardenShoppingStreetGame:_AddShopConflictEvent(areaId, taskData)
    self.BuildingAreaUi:AddShopConflictEvent(areaId, taskData)
end

function XUiSkyGardenShoppingStreetGame:_AddCustomerEventByTask(customerId, taskData)
    local CustomerUiNode = self._CustomerHeadList[customerId]
    if not CustomerUiNode then
        local eventData = taskData.EventData
        local XSgStreetCustomerEventType = XMVCA.XSkyGardenShoppingStreet.XSgStreetCustomerEventType
        local isDiscontent = eventData.Type == XSgStreetCustomerEventType.Discontent
        if isDiscontent then
            if self._Control:AutoDiscontentEvent() then
                self._Control:DoDiscontentEvent(eventData.Id, eventData.DiscontentAwardGold)
            end
        else
            if self._Control:AutoFeedbackEvent() then
                local feedback = eventData.FeedBackData
                self._Control:DoFeedbackEvent(eventData.Id, feedback)
            end
        end
        return
    end
    CustomerUiNode:SetTaskEvent(taskData, self)
end

-- UpdateHideTime
function XUiSkyGardenShoppingStreetGame:AddCustomerDelayCallback(customerId, time, cb)
    local customerData = self._CustomerDataList[customerId]
    if not customerData then return end
    return customerData:SetWaitTime(time, cb)
end

-- 移除所有定时器
function XUiSkyGardenShoppingStreetGame:RemoveCustomerDelayCallback(customerId, timerId)
    if not timerId then return end
    local customerData = self._CustomerDataList[customerId]
    if not customerData then return end
    customerData:RemoveWaitTime(timerId)
end

-- 绑定顾客Ui
function XUiSkyGardenShoppingStreetGame:_AddCustomerUi(customerId)
    local CustomerUiNode = self._CustomerHeadList[customerId]
    if not CustomerUiNode then
        CustomerUiNode = self:_GetCustomerUI()
        self._CustomerHeadList[customerId] = CustomerUiNode
    end
    local transform = self._CustomerDataList[customerId]:GetCacheTransform()
    CustomerUiNode.Transform.localPosition = CS.UnityEngine.Vector3(-2000, -2000, 0)
    CustomerUiNode:Open()
    CustomerUiNode:BindingCustomer(customerId, transform)
end

-- 移除顾客Ui
function XUiSkyGardenShoppingStreetGame:_RemoveCustomerUi(customerId)
    local CustomerUiNode = self._CustomerHeadList[customerId]
    if not CustomerUiNode then return end
    CustomerUiNode:UnBindingCustomer()
    CustomerUiNode:Close()
    self:_RecycleCustomerUI(CustomerUiNode)
    self._CustomerHeadList[customerId] = nil
end

-- 获取顾客Ui
function XUiSkyGardenShoppingStreetGame:_GetCustomerUI()
    local cache = self._HeadUiCache[1]
    if cache then
        table.remove(self._HeadUiCache, 1)
    else
        local ui = CS.UnityEngine.Object.Instantiate(self.Customer, self.Customer.transform.parent)
        return XUiSkyGardenShoppingStreetGameCustomer.New(ui, self)
    end
    return cache
end

-- 回收顾客Ui
function XUiSkyGardenShoppingStreetGame:_RecycleCustomerUI(headUi)
    table.insert(self._HeadUiCache, headUi)
end

-- 播放新闻
function XUiSkyGardenShoppingStreetGame:_ShowNews()
    local hasTips = self._Control:HasNewsOrGrapevinesTipsByTurn()
    if hasTips then
        local roundNum = self._Control:GetRunRound()
        local stageId = self._Control:GetCurrentStageId()
        local currentNewCheckNum = stageId * 1000 + roundNum
        local lastNewCheckNum = self._Control:GetLastShowNewsId()
        if currentNewCheckNum ~= lastNewCheckNum then
            self._Control:SetLastShowNewsId(currentNewCheckNum)
            XMVCA.XBigWorldUI:Open("UiSkyGardenShoppingStreetToastNews", {
                CloseCallback = function()
                    self:_ShowLimitTask()
                end,
            })
        else
            self:_ShowLimitTask()
        end
    else
        self:_ShowLimitTask()
    end
end

-- 新闻后显示显示任务
function XUiSkyGardenShoppingStreetGame:_ShowLimitTask()
    local hasLimitTask = self._Control:HasStageLimitTask()
    if hasLimitTask then
        XMVCA.XSkyGardenShoppingStreet:ConfirmPanel({
            ["Title"] = XMVCA.XBigWorldService:GetText("CommmonTipsTitle"),
            ["Tips"] = XMVCA.XBigWorldService:GetText("SG_SS_NewLimitTaskComfirmTips"),
            ["SureCallback"] = function()
                self._CurrentGameState = self._GameStateType._CheckShowSale
                self:OnBtnLightClick()
            end,
            ["CancelCallback"] = function()
                self:_CheckShowSale()
            end,
            ["IsShowToggle"] = false,
            ["IsTask"] = true,
        })
    else
        self:_CheckShowSale()
    end
end

-- 限时任务确认后检查促销
function XUiSkyGardenShoppingStreetGame:_CheckShowSale()
    local hasSale = self._Control:HasPromotion()
    if hasSale then
        self._CurrentGameState = self._GameStateType._ShowMascotMessage
        self:OnBtnChooseSaleClick()
    else
        self:_ShowMascotMessage()
    end
end

-- 促销后进入编辑显示吉祥物对话
function XUiSkyGardenShoppingStreetGame:_ShowMascotMessage()
    self.PanelPetUi:Open()
    self.PanelPetUi:StageStartTips()
end

--- 开始游戏
function XUiSkyGardenShoppingStreetGame:_StartGame()
    -- 数据同步
    self._X3cId2CustomerId = {}
    self._IsFinishGame = false
    self._CustomerDataList = {}
    self._CustomerCreateIndex = 0
    self._CustomerNum = self._Control:GetCustomerCount()
    if not self._CustomerCreateGapTimeMin then
        self._CustomerCreateGapTimeMin = tonumber(self._Control:GetGlobalConfigByKey("CustomerCreateGapTimeMin")) * 1000
        self._CustomerCreateGapTimeMax = tonumber(self._Control:GetGlobalConfigByKey("CustomerCreateGapTimeMax")) * 1000
        
        self._CustomerWaitTimeMin = tonumber(self._Control:GetGlobalConfigByKey("CustomerWaitTimeMin")) * 1000
        self._CustomerWaitTimeMax = tonumber(self._Control:GetGlobalConfigByKey("CustomerWaitTimeMax")) * 1000
        self._CustomerCreateRamdomNum = tonumber(self._Control:GetGlobalConfigByKey("CustomerCreateRamdomNum"))
        self._SatisfactionAutoGrowTime =  tonumber(self._Control:GetGlobalConfigByKey("SatisfactionAutoGrowTime")) * 1000
        self._SatisfactionAutoGrowNum =  tonumber(self._Control:GetGlobalConfigByKey("SatisfactionAutoGrowNum"))
    end
    self._CreateCustemerTime = math.random(self._CustomerCreateGapTimeMin, self._CustomerCreateGapTimeMax)

    if self.RecordingLoop then self.RecordingLoop.gameObject:PlayTimelineAnimation(nil, nil, CS.UnityEngine.Playables.DirectorWrapMode.Loop) end
    -- 游戏状态
    self._StartGameStatus = true
    self._TotalTimeCount = 0
    self._UpdateSatisfactionTime = 0

    XTool.UpdateDynamicItem(self._TaskGridDotUi, nil, self.GridDot, XUiSkyGardenShoppingStreetGameTargetDot, self)
    self.BuildingAreaUi:SetEditMode(false)
    self.BtnTarget.gameObject:SetActive(false)
    self.PanelBuild.gameObject:SetActive(false)
    self.PanelOperate.gameObject:SetActive(true)
    self.PanelPetUi:Close()

    self:_SetTimeScaleByScaleIndex(self._Control:GetGameSpeedIndex(), true)
    self:_RegisterSchedules()
    self._Control:X3CSetStageStatus(XMVCA.XSkyGardenShoppingStreet.X3CStageStatus.Running)
end

-- 顾客等待完成进行下一个任务回调
function XUiSkyGardenShoppingStreetGame:_CustomerWaitFinishNextTask(customerId)
    self:_DoCustomerTask(customerId)
end

-- 完成顾客任务列表的移动任务
function XUiSkyGardenShoppingStreetGame:_CustomerMoveShopFinish(customerId, isArrive)
    local customerData = self._CustomerDataList[customerId]
    local taskData = customerData:GetCurrentTask()
    if not taskData then
        self:_DestroyCustomer(customerId)
        return
    end
    local isTrueData = taskData.Type ~= XMVCA.XSkyGardenShoppingStreet.XSgStreetCustomerCommandType.Fake
    if isTrueData then
        self._Control:ClientAddResourceByAwardGold(taskData.ShopAwardGold)
    end

    -- 事件处理
    local eventData = taskData.EventData
    if eventData then
        local XSgStreetCustomerEventType = XMVCA.XSkyGardenShoppingStreet.XSgStreetCustomerEventType
        if eventData.Type == XSgStreetCustomerEventType.Discontent then
            -- 不满 顾客头上
            self:_AddCustomerEventByTask(customerId, taskData)
        elseif eventData.Type == XSgStreetCustomerEventType.Emergency then
            -- 冲突 商铺上
            local areaId = self._Control:GetAreaIdByShopId(taskData.TargetId)
            self:_AddShopConflictEvent(areaId, taskData)
        elseif eventData.Type == XSgStreetCustomerEventType.FeedBack then
            -- 反馈 顾客头上
            self:_AddCustomerEventByTask(customerId, taskData)
        end
    end
    customerData:FinishCurrentTask()

    -- 到达 下一个任务
    if isArrive then
        customerData:SetWaitTime(math.random(self._CustomerWaitTimeMin, self._CustomerWaitTimeMax), self.CustomerWaitFinishNextTask)
    else
        self:_DoCustomerTask(customerId)
    end
end

-- ui移动结束
function XUiSkyGardenShoppingStreetGame:CheckUiRunFinishCallback(customerId, isArrive)
    self:_CustomerMoveShopFinish(customerId, isArrive)
end

-- 移动完成返回
function XUiSkyGardenShoppingStreetGame:_CustomerMoveFinish(data)
    local x3cId = data.NpcId
    local customerId = self._X3cId2CustomerId[x3cId]
    local isArrive = data.IsArrive
    
    local CustomerUiNode = self._CustomerHeadList[customerId]
    if CustomerUiNode then
        CustomerUiNode:CheckFinishCallback(isArrive)
    else
        self:_CustomerMoveShopFinish(customerId, isArrive)
    end
end

-- 触发下一个任务
function XUiSkyGardenShoppingStreetGame:_DoCustomerTask(customerId)
    local customerData = self._CustomerDataList[customerId]
    local x3cId = customerData:GetX3CNpcId()
    -- test not scene
    if not x3cId then
        self:_CustomerMoveShopFinish(customerId, false)
        return
    end
    local taskData = customerData:GetCurrentTask()
    if taskData then
        local areaId = self._Control:GetAreaIdByShopId(taskData.TargetId)
        local needEnterShop = taskData.Type ~= XMVCA.XSkyGardenShoppingStreet.XSgStreetCustomerCommandType.Fake
        local eventData = taskData.EventData
        if eventData and eventData.Type then
            needEnterShop = true
        end
        self._Control:X3CCustomRunTask(x3cId, areaId, needEnterShop)
    else
        self._Control:X3CCustomRunTask(x3cId, 0)
    end
end

function XUiSkyGardenShoppingStreetGame:_FinishCheck()
    -- 完成所有任务检查
    local hasRunning = false
    for _, v in pairs(self._CustomerDataList) do
        if v:IsRunning() then
            hasRunning = true
            break
        end
    end
    if not hasRunning and self._CustomerNum <= 0 then
        self._IsFinishGame = true
    end
end

-- 等待完成销毁角色
function XUiSkyGardenShoppingStreetGame:_CustomerWaitFinishDestroy(customerId)
    self:_RemoveCustomerUi(customerId)
    local customerData = self._CustomerDataList[customerId]
    customerData:RemoveRunning()
    local x3cId = customerData:GetX3CNpcId()
    if x3cId then
        self._Control:X3CCustomerDestroy(x3cId)
        self._X3cId2CustomerId[x3cId] = nil
    end
    self:_FinishCheck()
end

--- 移除顾客
function XUiSkyGardenShoppingStreetGame:_DestroyCustomer(customerId)
    self._CustomerDataList[customerId]:SetWaitTime(self._TimerGap, self.CustomerWaitFinishDestroy)
end

-- 绑定初始化
function XUiSkyGardenShoppingStreetGame:_CreateCustomerFinish(customerId, transform, x3cId)
    local customerData = self._CustomerDataList[customerId]
    customerData:SetWaitTime(1000, self.CustomerWaitFinishNextTask)
    customerData:CacheTransform(transform)
    customerData:SetX3CNpcId(x3cId)
    self._X3cId2CustomerId[x3cId] = customerId
    self:_AddCustomerUi(customerId)
end

--- 创建顾客
function XUiSkyGardenShoppingStreetGame:_CreateCustomer()
    if self._CustomerNum <= 0 then return end

    self._CustomerNum = self._CustomerNum - 1
    self._CustomerCreateIndex = self._CustomerCreateIndex + 1
    local customerData = self._Control:GetCustomerByIndex(self._CustomerCreateIndex)
    if not customerData then return end

    customerData:ResetRunData(self._CustomerCreateIndex)
    if not customerData:GetCurrentTask() then return end

    self._CustomerDataList[self._CustomerCreateIndex] = customerData
    local res = self._Control:X3CCustomerCreate(self._CustomerCreateIndex)
    if res then
        self:_CreateCustomerFinish(self._CustomerCreateIndex, res.NpcTransform, res.NpcId)
    else
        self:_DoCustomerTask(self._CustomerCreateIndex)
    end
end

--- 检查顾客创建逻辑
function XUiSkyGardenShoppingStreetGame:_CheckAndCreateCustomer()
    if self._CreateCustemerTime <= 0 then return end

    self._CreateCustemerTime = self._CreateCustemerTime - self._FrameRunTime
    if self._CreateCustemerTime <= 0 then
        -- 创建顾客
        local createCustomerNum = math.random(1, self._CustomerCreateRamdomNum)
        for i = 1, createCustomerNum do
            self:_CreateCustomer()
        end
        -- 是否需要继续创建
        if self._CustomerNum > 0 then
            self._CreateCustemerTime = math.random(self._CustomerCreateGapTimeMin, self._CustomerCreateGapTimeMax)
        else
            self._CreateCustemerTime = 0
            self:_FinishCheck()
        end
    end
end

-- 更新顾客等等数据 -- 不新起定时器了，因为暂停要全部暂停，如果分开定时器后面还要同时关闭同时开启
function XUiSkyGardenShoppingStreetGame:_UpdateCustomer()
    if self._IsStop then return end
    if self._IsFinishGame then
        self._IsFinishGame = false
        self._Control:EndRunRound(function()
            self:_EndGame()
        end)
        return
    end
    for _, v in pairs(self._CustomerDataList) do
        if v:IsRunning() then
            v:UpdateRunTime(self._FrameRunTime)
        end
    end
end

-- 更新时间
function XUiSkyGardenShoppingStreetGame:_UpdateTimer()
    if not self._StartGameStatus then return end
    if self._IsStop then return end
    self._FrameRunTime = self._TimerGap * self._TimeScale
    self._TotalTimeCount = self._TotalTimeCount + self._FrameRunTime
    self._UpdateSatisfactionTime = self._UpdateSatisfactionTime + self._FrameRunTime
    if self._UpdateSatisfactionTime > self._SatisfactionAutoGrowTime then
        self._UpdateSatisfactionTime = self._UpdateSatisfactionTime - self._SatisfactionAutoGrowTime
        self._Control:ClientSatisfactionGrow(self._SatisfactionAutoGrowNum)
    end
    self:_CheckAndCreateCustomer()
    self:_UpdateCustomer()
end

-- 结束游戏
function XUiSkyGardenShoppingStreetGame:_EndGame()
    -- 恢复状态
    self:_RemoveAllTimer()
    self:_ResetAllRunData()
    self.BuildingAreaUi:ResetAllShopConflictEvent()

    if self.RecordingLoop then self.RecordingLoop.gameObject:StopTimelineAnimation(false, true) end
    self._StartGameStatus = false
    -- 每日统计
    self:_OpenLastEndCount()
end

-- 昨日统计
function XUiSkyGardenShoppingStreetGame:_OpenLastEndCount()
    self._CurrentGameState = self._GameStateType._CheckLimitTask
    XMVCA.XBigWorldUI:Open("UiSkyGardenShoppingStreetPopupRoundEnd")
end

-- 限时任务完成检查
function XUiSkyGardenShoppingStreetGame:_CheckLimitTask()
    self._Control:CleanStageDataCache()

    XMVCA.XSkyGardenShoppingStreet:ShowFinishInfo()
    XMVCA.XSkyGardenShoppingStreet:SgStreetFinishTasksRequest()

    local isFinishTask = self._Control:IsFinishLimitTask()
    if isFinishTask then
        -- 打开限时任务完成界面，关闭回调
        -- self._CurrentGameState = self._GameStateType._CheckStageFinish
        XMVCA.XBigWorldUI:Open("UiSkyGardenShoppingStreetToastTaskSettlement", function ()
            self:_CheckStageFinish()
        end)
    else
        self:_CheckStageFinish()
    end
end

-- 完成关卡检查
function XUiSkyGardenShoppingStreetGame:_CheckStageFinish()
    local isFinishStage = self._Control:IsFinishAllStageTask()
    if isFinishStage then
        -- 打开完成界面，关闭当前界面
        XMVCA.XSkyGardenShoppingStreet:TryFinishStage()
    else
        self:_ShowEdit()
    end
end

function XUiSkyGardenShoppingStreetGame:_ResetAllRunData()
    local removeHeadUiIds = {}
    for _customerId, v in pairs(self._CustomerHeadList) do
        removeHeadUiIds[_customerId] = true
    end
    for _customerId, _ in pairs(removeHeadUiIds) do
        self:_RemoveCustomerUi(_customerId)
    end

    if self._CustomerDataList then
        for customerId, v in pairs(self._CustomerDataList) do
            if v:IsRunning() then
                v:RemoveRunning()
                local x3cId = v:GetX3CNpcId()
                self._Control:X3CCustomerDestroy(x3cId)
            end
        end
    end
end
--endregion
--endregion

return XUiSkyGardenShoppingStreetGame
