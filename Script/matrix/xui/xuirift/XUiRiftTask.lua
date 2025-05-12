local XDynamicGridTask = require("XUi/XUiTask/XDynamicGridTask")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
---@class XUiRiftTask:XLuaUi 大秘境任务界面
---@field _Control XRiftControl
local XUiRiftTask = XLuaUiManager.Register(XLuaUi, "UiRiftTask")

function XUiRiftTask:OnAwake()
    self:InitTabGroup()
    self:InitDynamicTable()
    self:RegisterEvent()
    self:InitTimes()

    local itemIds = { XDataCenter.ItemManager.ItemId.RiftGold, XDataCenter.ItemManager.ItemId.RiftCoin }
    self.AssetActivityPanel = XUiHelper.NewPanelActivityAssetSafe(itemIds, self.PanelSpecialTool, self)
end

function XUiRiftTask:OnEnable()
    self.Super.OnEnable(self)
    self.BtnGroup:SelectIndex(self.SelectIndex or 1)
    XEventManager.AddEventListener(XEventId.EVENT_FINISH_MULTI, self.UpdateDynamicTable, self)
end

function XUiRiftTask:OnDisable()
    self.Super.OnDisable(self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FINISH_MULTI, self.UpdateDynamicTable, self)
end

function XUiRiftTask:InitTimes()
    self:SetAutoCloseInfo(self._Control:GetActivityEndTime(), function(isClose)
        if isClose then
            XLuaUiManager.RunMain()
            XUiManager.TipMsg(XUiHelper.GetText("ActivityAlreadyOver"))
        end
    end)
end

function XUiRiftTask:InitTabGroup()
    self.TabBtns = {}
    self.TaskGroupIdList = self._Control:GetTaskGroupIdList()
    for i = 1, 2 do
        local tmpBtn = self["BtnTabTask" .. i]
        if tmpBtn then
            tmpBtn:SetName(self._Control:GetTaskConfigById(i).Name)
            table.insert(self.TabBtns, tmpBtn)
        end
    end

    self.BtnGroup:Init(self.TabBtns, function(index) self:OnSelectedTog(index) end)
end

function XUiRiftTask:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.TaskList)
    self.DynamicTable:SetProxy(XDynamicGridTask, self)
    self.DynamicTable:SetDelegate(self)
    self.GridTask.gameObject:SetActiveEx(false)
end

function XUiRiftTask:OnSelectedTog(index)
    if self.SelectIndex == index then
        return
    end
    self.SelectIndex = index
    self:PlayAnimation("QieHuan")
    self:UpdateDynamicTable()
end

function XUiRiftTask:UpdateDynamicTable()
    local index = self.SelectIndex
    self.TaskDataList = XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(self.TaskGroupIdList[index])
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
function XUiRiftTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX or event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        local taskData = self.TaskDataList[index]
        grid:ResetData(taskData)
        grid:SetTaskLock(false)
    end
end

function XUiRiftTask:OnNotify(evt, ...)
    if evt == XEventId.EVENT_FINISH_TASK then
        self:UpdateDynamicTable()
    end
end

function XUiRiftTask:OnGetEvents()
    return { XEventId.EVENT_FINISH_TASK }
end

function XUiRiftTask:RegisterEvent()
    self:RegisterClickEvent(self.BtnBack, self.Close)
    self:RegisterClickEvent(self.BtnMainUi, function() XLuaUiManager.RunMain() end)
end

function XUiRiftTask:UpdateRedPoint()
    for i = 1, 2 do
        if self.TabBtns[i] then
            local isShowRed = XDataCenter.TaskManager.CheckLimitTaskList(self.TaskGroupIdList[i])
            self.TabBtns[i]:ShowReddot(isShowRed)
        end
    end
end