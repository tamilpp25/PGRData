local XUiBabelTowerTask = XLuaUiManager.Register(XLuaUi, "UiBabelTowerTask")

function XUiBabelTowerTask:OnAwake()
    self.TaskGroupIndex = 1
    self.AssetPanel =    XUiPanelAsset.New(
    self,
    self.PanelAsset,
    XDataCenter.ItemManager.ItemId.FreeGem,
    XDataCenter.ItemManager.ItemId.ActionPoint,
    XDataCenter.ItemManager.ItemId.Coin
    )
    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end
    self.BtnMainUi.CallBack = function()
        self:OnBtnMainUiClick()
    end

    self.DynamicTable = XDynamicTableNormal.New(self.SViewTask.gameObject)
    self.DynamicTable:SetProxy(XDynamicGridTask)
    self.DynamicTable:SetDelegate(self)

    -- XEventManager.AddEventListener(XEventId.EVENT_BABEL_ACTIVITY_STATUS_CHANGED, self.CheckActivityStatus, self)
    XEventManager.AddEventListener(XEventId.EVENT_TASK_SYNC, self.OnTaskChangeSync, self)

    -- XFubenBabelTowerConfigs.ActivityType
    self.ActivityType = nil
end

function XUiBabelTowerTask:OnDestroy()
    self:StopCountDown()
    -- XEventManager.RemoveEventListener(XEventId.EVENT_BABEL_ACTIVITY_STATUS_CHANGED, self.CheckActivityStatus, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_TASK_SYNC, self.OnTaskChangeSync, self)
end

function XUiBabelTowerTask:OnBtnBackClick()
    self:Close()
end

function XUiBabelTowerTask:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiBabelTowerTask:OnStart(activityType)
    self.TaskGroupIndex = activityType
    self.ActivityType = activityType
    self:OnTaskChangeSync()
    self:CreateCountDown()
    -- 设置背景
    self.RImgBg:SetRawImage(XFubenBabelTowerConfigs.GetActivityConfigValue("TaskBigBg")[activityType])
    -- 开启自动关闭检查
    local endTime = XDataCenter.FubenBabelTowerManager.GetEndTime(activityType)
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            XDataCenter.FubenBabelTowerManager.HandleActivityEndTime(activityType)
        end
    end)
end

function XUiBabelTowerTask:CreateCountDown()
    self:StopCountDown()
    local time = XTime.GetServerNowTimestamp()
    -- local curActivityNo = XDataCenter.FubenBabelTowerManager.GetCurrentActivityNo()
    -- if not curActivityNo then
    --     return
    -- end
    -- local activityTemplate = XFubenBabelTowerConfigs.GetBabelTowerActivityTemplateById(curActivityNo)
    -- if not activityTemplate then
    --     return
    -- end

    local endTime = XDataCenter.FubenBabelTowerManager.GetEndTime(self.ActivityType) --XFunctionManager.GetEndTimeByTimeId(activityTemplate.ActivityTimeId)
    if not endTime then
        return
    end
    local leftTimeDesc = CS.XTextManager.GetText("BabelTowerLeftTimeDesc")
    self.TxtTime.text = string.format("%s%s", leftTimeDesc, XUiHelper.GetTime(endTime - time, XUiHelper.TimeFormatType.ACTIVITY))
    self.Timer = XScheduleManager.ScheduleForever(
    function()
        time = XTime.GetServerNowTimestamp()
        if time > endTime then
            self:StopCountDown()
            return
        end
        self.TxtTime.text =        string.format(
        "%s%s",
        leftTimeDesc,
        XUiHelper.GetTime(endTime - time, XUiHelper.TimeFormatType.ACTIVITY)
        )
    end,
    XScheduleManager.SECOND,
    0
    )
end

function XUiBabelTowerTask:StopCountDown()
    if self.Timer ~= nil then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiBabelTowerTask:OnEnable()
    XUiBabelTowerTask.Super.OnEnable(self)
    self:CheckActivityStatus()
end

function XUiBabelTowerTask:CheckActivityStatus()
    if not XLuaUiManager.IsUiShow("UiBabelTowerTask") then
        return
    end
    XDataCenter.FubenBabelTowerManager.HandleActivityEndTime(self.ActivityType)
end

function XUiBabelTowerTask:OnTaskChangeSync()
    self.BabelTowerTasks = XDataCenter.FubenBabelTowerManager.GetTasksByGroupIndex(self.TaskGroupIndex)
    self.DynamicTable:SetDataSource(self.BabelTowerTasks)
    self.DynamicTable:ReloadDataASync()
    self.ImgEmpty.gameObject:SetActiveEx(#self.BabelTowerTasks <= 0)
end

--动态列表事件
function XUiBabelTowerTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.BabelTowerTasks[index]
        if not data then
            return
        end
        grid.RootUi = self
        grid:ResetData(data)
    end
end