local XDynamicGridTask = require("XUi/XUiTask/XDynamicGridTask")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
---@field _Control XMusicGameActivityControl
---@class XUiMusicGameActivityTask : XLuaUi
local XUiMusicGameActivityTask = XLuaUiManager.Register(XLuaUi, "UiMusicGameActivityTask")

function XUiMusicGameActivityTask:OnAwake()
    self:InitTimes()
    self:InitButton()
    self:InitDynamicTable()
end

function XUiMusicGameActivityTask:InitTimes()
    self:SetAutoCloseInfo(self._Control:GetActivityEndTime(), function(isClose)
        if isClose then
            XLuaUiManager.RunMain()
            XUiManager.TipMsg(XUiHelper.GetText("ActivityAlreadyOver"))
        end
    end)
end

function XUiMusicGameActivityTask:InitButton()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, function() XLuaUiManager.RunMain() end)

    self.TabBtns = {}
    for i = 1, 2 do
        local tmpBtn = self["BtnTabTask" .. i]
        if tmpBtn then
            table.insert(self.TabBtns, tmpBtn)
        end
    end
    
    self.BtnGroup:Init(self.TabBtns, function(index) self:OnSelectedTog(index) end)
end

function XUiMusicGameActivityTask:OnSelectedTog(index)
    if self.SelectIndex == index then
        return
    end
    self.SelectIndex = index
    -- self:PlayAnimation("QieHuan")
    self:UpdateDynamicTable()
end

function XUiMusicGameActivityTask:InitDynamicTable()
    self.TaskGroupIds = XMVCA.XMusicGameActivity:GetTaskGroupIds()
    self.DynamicTable = XDynamicTableNormal.New(self.SViewTask)
    self.DynamicTable:SetProxy(XDynamicGridTask, self)
    self.DynamicTable:SetDelegate(self)
    self.GridTask.gameObject:SetActiveEx(false)
end

function XUiMusicGameActivityTask:OnStart()
    self.BtnGroup:SelectIndex(self.SelectIndex or 1)
end

function XUiMusicGameActivityTask:OnEnable()
    self.Super.OnEnable(self)

    self.AssetPanel = XUiHelper.NewPanelActivityAssetSafe({ XDataCenter.ItemManager.ItemId.MusicGameArrangementItem }, self.PanelSpecialTool, self)
    XEventManager.AddEventListener(XEventId.EVENT_FINISH_MULTI, self.UpdateDynamicTable, self)
end

function XUiMusicGameActivityTask:OnDisable()
    self.Super.OnDisable(self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FINISH_MULTI, self.UpdateDynamicTable, self)
end

function XUiMusicGameActivityTask:UpdateDynamicTable()
    local index = self.SelectIndex
    self.TaskDataList = XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(self.TaskGroupIds[index])
    local allAchieveTasks = {}
    for _, v in pairs(self.TaskDataList) do
        if v.State == XDataCenter.TaskManager.TaskState.Achieved then
            table.insert(allAchieveTasks, v.Id)
        end
    end
    if not XTool.IsTableEmpty(allAchieveTasks) then
        table.insert(self.TaskDataList, 1, { ReceiveAll = true, AllAchieveTaskDatas = allAchieveTasks }) -- 领取全部
    end
    self.DynamicTable:SetDataSource(self.TaskDataList)
    self.DynamicTable:ReloadDataASync()
    self.ImgEmpty.gameObject:SetActiveEx(XTool.IsTableEmpty(self.TaskDataList))
    self:UpdateRedPoint()
end

---@param grid XDynamicGridTask
function XUiMusicGameActivityTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX or event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        local taskData = self.TaskDataList[index]
        grid:ResetData(taskData)
        grid:SetTaskLock(false)
    end
end

function XUiMusicGameActivityTask:UpdateRedPoint()
    for i = 1, 2 do
        if self.TabBtns[i] then
            local isShowRed = XDataCenter.TaskManager.CheckLimitTaskList(self.TaskGroupIds[i])
            self.TabBtns[i]:ShowReddot(isShowRed)
        end
    end
end

function XUiMusicGameActivityTask:OnNotify(evt, ...)
    if evt == XEventId.EVENT_FINISH_TASK then
        self:UpdateDynamicTable()
    end
end

function XUiMusicGameActivityTask:OnGetEvents()
    return { XEventId.EVENT_FINISH_TASK }
end

return XUiMusicGameActivityTask
