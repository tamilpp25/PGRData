local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XDynamicGridTask = require("XUi/XUiTask/XDynamicGridTask")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
--大逃杀任务界面
local XUiEscapeTask = XLuaUiManager.Register(XLuaUi, "UiEscapeTask")

function XUiEscapeTask:OnAwake()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self:InitTabGroup()
    self:InitDynamicTable()
    self:AddListener()
end

function XUiEscapeTask:OnStart()
    self:InitTimes()
end

function XUiEscapeTask:OnEnable()
    XUiEscapeTask.Super.OnEnable(self)
    self.BtnGroup:SelectIndex(self.SelectIndex or 1)
    self:UpdateRedPoint()
end

function XUiEscapeTask:InitTimes()
    self:SetAutoCloseInfo(XDataCenter.EscapeManager.GetActivityEndTime(), function(isClose)
        if isClose then
            XDataCenter.EscapeManager.HandleActivityEndTime()
        end
    end)
end

function XUiEscapeTask:InitTabGroup()
    self.TabBtns = {}
    self.TaskGroupIdList = XEscapeConfigs.GetTaskGroupIdList()
    for i, id in ipairs(self.TaskGroupIdList) do
        local tmpBtn = self["BtnTabTask" .. i]
        if tmpBtn then
            tmpBtn:SetName(XEscapeConfigs.GetTaskName(id))
            table.insert(self.TabBtns, tmpBtn)
        end
    end

    self.BtnGroup:Init(self.TabBtns, function(index) self:OnSelectedTog(index) end)
end

function XUiEscapeTask:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.TaskList)
    self.DynamicTable:SetProxy(XDynamicGridTask, self)
    self.DynamicTable:SetDelegate(self)
    self.GridTask.gameObject:SetActiveEx(false)
end

function XUiEscapeTask:OnSelectedTog(index)
    if self.SelectIndex == index then
        return
    end
    self.SelectIndex = index
    self:PlayAnimation("QieHuan")
    self:UpdateDynamicTable()
end

function XUiEscapeTask:UpdateDynamicTable()
    local index = self.SelectIndex
    local taskGroupId = self.TaskGroupIdList[index]
    if not taskGroupId then
        return
    end

    self.TaskDataList = XDataCenter.EscapeManager.GetTaskDataList(taskGroupId)
    self.DynamicTable:SetDataSource(self.TaskDataList)
    self.DynamicTable:ReloadDataASync()
    self.ImgEmpty.gameObject:SetActiveEx(XTool.IsTableEmpty(self.TaskDataList))
end

function XUiEscapeTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local taskData = self.TaskDataList[index]
        grid:ResetData(taskData)
    end
end

function XUiEscapeTask:OnNotify(evt, ...)
    if evt == XEventId.EVENT_FINISH_TASK then
        self:UpdateDynamicTable()
        self:UpdateRedPoint()
    end
end

function XUiEscapeTask:OnGetEvents()
    return { XEventId.EVENT_FINISH_TASK }
end

function XUiEscapeTask:AddListener()
    self:RegisterClickEvent(self.BtnBack, self.Close)
    self:RegisterClickEvent(self.BtnMainUi, function() XLuaUiManager.RunMain() end)
end

function XUiEscapeTask:UpdateRedPoint()
    for i, escapeTaskId in ipairs(self.TaskGroupIdList) do
        if self.TabBtns[i] then
            local isShowRed = XDataCenter.EscapeManager.CheckTaskCanRewardByEscapeTaskId(escapeTaskId)
            self.TabBtns[i]:ShowReddot(isShowRed)
        end
    end
end