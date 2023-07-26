-- 新手任务二期
local XUiNewbieTaskMain = XLuaUiManager.Register(XLuaUi, "UiNewbieTaskMain")
local XUiNewbieTaskAnim = require("XUi/XUiNewbieTask/SpineAnim/XUiNewbieTaskAnim")
local XUiGridNewbieTask = require("XUi/XUiNewbieTask/XUiGridNewbieTask")
local XUiGridNewbieActive = require("XUi/XUiNewbieTask/XUiGridNewbieActive")
local XUiPanelNewbieTaskSuccess = require("XUi/XUiNewbieTask/XUiPanelNewbieTaskSuccess")

local FULL_PROGRESS = 0.9

function XUiNewbieTaskMain:OnAwake()
    self:RegisterUiEvents()

    self.PanelNewbieTask.gameObject:SetActiveEx(true)
    self.PanelSpine.gameObject:SetActiveEx(true)
    self.PlayerTaskSuccess.gameObject:SetActiveEx(false)
    self.PanelNoneTask.gameObject:SetActiveEx(false)
    self.GridNewbieTaskItem.gameObject:SetActiveEx(false)
    self.PanelNewbieActive.gameObject:SetActiveEx(false)
    
    self.BtnDayTab = {}
    self.TotalProgress = {}
end

function XUiNewbieTaskMain:OnStart()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    
    self.RegisterDay = XDataCenter.NewbieTaskManager.GetNewbieTaskRegisterDay()
    self.NewbieActiveness = XTaskConfig.GetNewbieTaskTwoActivenessTemplate()
    self:InitDynamicTable()
    self:InitView()
    
    -- Spine动画
    self.NewbieTaskAnim = XUiNewbieTaskAnim.New(self.PanelLeft, self)
    self.NewbieTaskSuccess = XUiPanelNewbieTaskSuccess.New(self.PlayerTaskSuccess, self)
    
    self.CurrentIndex = self:GetNewRegisterDay()
end

function XUiNewbieTaskMain:OnEnable()
    self.TabBtnGroup:SelectIndex(self.CurrentIndex or 1)
    self:RefreshBtnDayTabStatus()
    self:RefreshProgress()
    
    self.NewbieTaskAnim:OnEnable()
    
    -- 保存每日是否进入过
    XDataCenter.NewbieTaskManager.SaveDailyFirstEnter()
    self:CheckRewardReceiveStatus()
end

function XUiNewbieTaskMain:OnGetEvents()
    return{
        XEventId.EVENT_FINISH_TASK,
        XEventId.EVENT_TASK_SYNC,
        XEventId.EVENT_NEWBIE_TASK_UNLOCK_PERIOD_CHANGED,
    }
end

function XUiNewbieTaskMain:OnNotify(event, ...)
    if event == XEventId.EVENT_FINISH_TASK or event == XEventId.EVENT_TASK_SYNC then
        self:RefreshBtnDayTabStatus()
        self:SetupDynamicTable()
        self:RefreshProgress()
        self:CheckTabAnimation()
    elseif event == XEventId.EVENT_NEWBIE_TASK_UNLOCK_PERIOD_CHANGED then
        self:RefreshBtnDayTabStatus()
    end
end

function XUiNewbieTaskMain:OnDisable()
    self.NewbieTaskAnim:OnDisable()
end

function XUiNewbieTaskMain:OnDestroy()
    self.NewbieTaskAnim:OnDestroy()
end

function XUiNewbieTaskMain:InitView()
    self:InitDayTab()
    self:InitProgress()
end

function XUiNewbieTaskMain:InitDayTab()
    self.BtnNewbieTaskTab.gameObject:SetActiveEx(false)
    self.BtnDayTab = {}
    for i = 1, #self.RegisterDay do
        local go = XUiHelper.Instantiate(self.BtnNewbieTaskTab, self.TabBtnGroup.transform)
        local btn = go:GetComponent("XUiButton")
        btn:SetName(CSXTextManagerGetText("NewbieDayTab2", XTool.ConvertNumberString(self.RegisterDay[i])))
        self.BtnDayTab[i] = btn
        btn.gameObject:SetActiveEx(true)
    end
    self.TabBtnGroup:Init(self.BtnDayTab, function(tabIndex)
        self:OnClickTabCallBack(tabIndex)
    end)
end

function XUiNewbieTaskMain:InitProgress()
    self.TotalCount = #self.NewbieActiveness.Activeness
    self.MaxProgress = self.NewbieActiveness.Activeness[self.TotalCount]
    local uiName = self.PanelNewbieActive.name
    for i = 1, self.TotalCount do
        local progress = self.TotalProgress[i]
        if not progress then
            local ui = XUiHelper.Instantiate(self.PanelNewbieActive, self.ImgProgress.transform)
            ui.name = string.format("%s%s", uiName, i)
            progress = XUiGridNewbieActive.New(ui, self, i, self.NewbieActiveness.Activeness[i], self.MaxProgress)
            self.TotalProgress[i] = progress
            ui.gameObject:SetActiveEx(true)
        end
    end
    
    self.ImgProgressRect = self.ImgProgress:GetComponent("RectTransform")
    self.TemplatePosition = self.PanelNewbieActive.transform.localPosition
    self.TemplateRect = self.PanelNewbieActive:GetComponent("RectTransform")

    -- 设置总进度值 (读进度奖励配置表的最后的一个值)
    self.TxtTotalProgress.text = string.format("/%d", self.MaxProgress)
end

function XUiNewbieTaskMain:OnClickTabCallBack(tabIndex)
    local day = self.RegisterDay[tabIndex]
    
    if not XDataCenter.NewbieTaskManager.CheckUnlockPeriod(day) then
        XUiManager.TipMsg(CSXTextManagerGetText("NewbieDayUnlock"))
        -- 未解锁提醒动画
        self.NewbieTaskAnim:ActiveTriggerAnimation(XNewbieEventType.CLICK_UNLOCK_TAB)
        return
    end
    
    self.CurrentIndex = tabIndex
    self.CurrentDay = day
    
    self:SetupDynamicTable()
    local isSave = XDataCenter.NewbieTaskManager.SaveRegisterDayBtnClick(day)
    if isSave then
        self:RefreshBtnDayTabStatus()
    end
end

function XUiNewbieTaskMain:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.SViewTask)
    self.DynamicTable:SetProxy(XUiGridNewbieTask, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiNewbieTaskMain:SetupDynamicTable()
    self.DynamicTableDataList = XDataCenter.NewbieTaskManager.GetTaskDataList(self.CurrentDay)
    self.PanelNoneTask.gameObject:SetActive(#self.DynamicTableDataList <= 0)
    self.DynamicTable:SetDataSource(self.DynamicTableDataList)
    self.DynamicTable:ReloadDataSync(1)
end

function XUiNewbieTaskMain:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.DynamicTableDataList[index])
    end
end

-- 显示最新解锁的任务
function XUiNewbieTaskMain:GetNewRegisterDay()
    local index = 1
    for i, day in pairs(self.RegisterDay) do
        if XDataCenter.NewbieTaskManager.CheckUnlockPeriod(day) then
            if i > index then
                index = i
            end
        end
    end
    return index
end

function XUiNewbieTaskMain:RefreshBtnDayTabStatus()
    for i, btn in pairs(self.BtnDayTab) do
        local day = self.RegisterDay[i]
        -- 刷新红点 和 按钮锁定状态
        if XDataCenter.NewbieTaskManager.CheckUnlockPeriod(day) then
            if self.CurrentIndex ~= i then
                btn:SetButtonState(CS.UiButtonState.Normal)
            end
            btn:ShowReddot(XDataCenter.NewbieTaskManager.CheckRegisterDayRedPoint(day))
            -- 刷新任务Tag
            btn:ShowTag(XDataCenter.NewbieTaskManager.CheckTaskFinishByDay(day))
        else
            btn:SetButtonState(CS.UiButtonState.Disable)
            btn:ShowReddot(false)
            btn:ShowTag(false)
        end
    end
end

function XUiNewbieTaskMain:RefreshProgressTransform()
    -- 异形屏适配需要
    XScheduleManager.ScheduleOnce(function()
        if not self.GameObject or not self.GameObject:Exist() then
            return
        end
        
        -- 更新位置
        local totalWidth = self.ImgProgressRect.rect.size.x
        local activeWidthOffset = self.TemplateRect.rect.size.x / 2
        for i = 1, self.TotalCount do
            local currentProgress = self.NewbieActiveness.Activeness[i] * 1.0 / self.MaxProgress * FULL_PROGRESS
            local progress = self.TotalProgress[i]
            if progress then
                progress.Transform:GetComponent("RectTransform").anchoredPosition3D = CS.UnityEngine.Vector3(currentProgress * totalWidth - activeWidthOffset, self.TemplatePosition.y, self.TemplatePosition.z)
            end
        end
    end, 1)
end

function XUiNewbieTaskMain:RefreshProgress()
    -- 刷新进度奖励位置
    self:RefreshProgressTransform()
    
    local progressNumber = XDataCenter.NewbieTaskManager.GetCurrentTaskProgress()
    -- 当前进度值
    self.TxtCurProgress.text = progressNumber
    local currentProgress = progressNumber * 1.0 / self.MaxProgress * FULL_PROGRESS
    self.ImgProgress.fillAmount = (currentProgress > FULL_PROGRESS) and 1 or currentProgress

    for _, progress in pairs(self.TotalProgress) do
        progress:Refresh(progressNumber)
    end
end

-- 领取完奖励后的操作 如果有自选和非自选礼包直接打开
function XUiNewbieTaskMain:OnRewardTaskFinish(rewards)
    local asynOpenBagItem = asynTask(function(itemData, cb)
        XLuaUiManager.Open("UiBagItemInfoPanel", itemData, nil, nil, cb)
    end)

    local asynOpenSelectGift = asynTask(function(itemId, cb)
        XLuaUiManager.Open("UiNewbieSelectGift", itemId, cb)
    end)

    RunAsyn(function()
        for _, reward in pairs(rewards) do
            if XArrangeConfigs.GetType(reward.TemplateId) ~= XArrangeConfigs.Types.Item then -- 是道具
                goto CONTINUE
            end
            
            local itemData = XDataCenter.ItemManager.GetItem(reward.TemplateId)
            local data = XDataCenter.ItemManager.ConvertToGridData({ itemData })
            local itemId = data[1].Data.Id
            if not XDataCenter.ItemManager.IsUseable(itemId) then
                goto CONTINUE
            end

            if XDataCenter.ItemManager.IsSelectGift(itemId) then
                -- 自选礼包
                asynOpenSelectGift(itemId)
            else
                -- 非自选礼包
                asynOpenBagItem(data[1])
            end
            
            :: CONTINUE ::
        end
        self:CheckRewardReceiveStatus()
    end)
end

-- 判断是否领取所有奖励 以及是否领取了荣誉奖励
function XUiNewbieTaskMain:CheckRewardReceiveStatus()
    if XDataCenter.NewbieTaskManager.CheckNewbieHonorReward() then
        self:Close()
    elseif XDataCenter.NewbieTaskManager.CheckTaskAllFinish() and XDataCenter.NewbieTaskManager.CheckProgressRewardAllReceive() then
        -- 荣誉界面不需要Spine动画了， 直接掉Disable方法
        self.NewbieTaskAnim:OnDisable()
        -- 开始展示荣誉奖励
        self.PanelNewbieTask.gameObject:SetActiveEx(false)
        self.PanelSpine.gameObject:SetActiveEx(false)
        self.PlayerTaskSuccess.gameObject:SetActiveEx(true)
        self:PlayAnimation("PlayerTaskSuccessEnable")
    else
        -- 有未领取的奖励
        self.PlayerTaskSuccess.gameObject:SetActiveEx(false)
    end
end

-- 检测是否播放页签动画
-- 条件是：领取完毕某个页签所有奖励
function XUiNewbieTaskMain:CheckTabAnimation()
    local isTaskFinish = XDataCenter.NewbieTaskManager.CheckTaskFinishByDay(self.CurrentDay)
    if isTaskFinish then
        self.NewbieTaskAnim:ActiveTriggerAnimation(XNewbieEventType.REWARD_TAB)
    end
end

function XUiNewbieTaskMain:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, self.OnBtnMainUiClick)
end

function XUiNewbieTaskMain:OnBtnBackClick()
    self:Close()
end

function XUiNewbieTaskMain:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

return XUiNewbieTaskMain