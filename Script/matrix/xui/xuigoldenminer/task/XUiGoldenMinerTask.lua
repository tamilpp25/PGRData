local XDynamicGridTask = require("XUi/XUiTask/XDynamicGridTask")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
---黄金矿工任务界面
---@class XUiGoldenMinerTask : XLuaUi
---@field _Control XGoldenMinerControl
local XUiGoldenMinerTask = XLuaUiManager.Register(XLuaUi, "UiGoldenMinerTask")

function XUiGoldenMinerTask:OnAwake()
    self:InitTabGroup()
    self:InitDynamicTable()
    self:AddListener()
end

function XUiGoldenMinerTask:OnStart()
    self:InitTimes()
    self.BtnGroup:SelectIndex(self.SelectIndex or 1)
end

function XUiGoldenMinerTask:OnEnable()
    XUiGoldenMinerTask.Super.OnEnable(self)
    self:UpdateDynamicTable()
    self:UpdateRedPoint()
end

function XUiGoldenMinerTask:OnNotify(evt, ...)
    if evt == XEventId.EVENT_FINISH_TASK then
        self:UpdateDynamicTable()
        self:UpdateRedPoint()
    end
end

function XUiGoldenMinerTask:OnGetEvents()
    return { XEventId.EVENT_FINISH_TASK }
end


--region Activity - AutoClose
function XUiGoldenMinerTask:InitTimes()
    self:SetAutoCloseInfo(self._Control:GetCurActivityEndTime(), function(isClose)
        if isClose then
            self._Control:HandleActivityEndTime()
        end
    end)
end
--endregion

--region Ui - TaskTabGroup
function XUiGoldenMinerTask:InitTabGroup()
    self.TabBtns = {}
    self._TaskGroupCfgList = self._Control:GetCfgTaskGroupList()
    for i, cfg in ipairs(self._TaskGroupCfgList) do
        local tmpBtn = self["BtnTabTask" .. i]
        if tmpBtn then
            tmpBtn:SetName(cfg.Name)
            table.insert(self.TabBtns, tmpBtn)
        end
    end

    self.BtnGroup:Init(self.TabBtns, function(index) self:OnSelectedTog(index) end)
end

function XUiGoldenMinerTask:OnSelectedTog(index)
    if self.SelectIndex == index then
        return
    end
    self.SelectIndex = index
    self:PlayAnimation("QieHuan")
    self:UpdateDynamicTable()
end
--endregion

--region Ui - TaskGrid DynamicTable
function XUiGoldenMinerTask:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.SViewTask)
    self.DynamicTable:SetProxy(XDynamicGridTask, self)
    self.DynamicTable:SetDelegate(self)
    self.GridTask.gameObject:SetActiveEx(false)
end

function XUiGoldenMinerTask:UpdateDynamicTable()
    local index = self.SelectIndex
    local taskGroupId = self._TaskGroupCfgList[index].Id
    if not taskGroupId then
        return
    end

    self.TaskDataList = self._Control:GetTaskDataList(taskGroupId)
    self.DynamicTable:SetDataSource(self.TaskDataList)
    self.DynamicTable:ReloadDataASync()
    self.ImgEmpty.gameObject:SetActiveEx(XTool.IsTableEmpty(self.TaskDataList))
end

function XUiGoldenMinerTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local taskData = self.TaskDataList[index]
        grid:ResetData(taskData)
    end
end
--endregion

--region Ui - RedPoint
function XUiGoldenMinerTask:UpdateRedPoint()
    for i, cfg in ipairs(self._TaskGroupCfgList) do
        if self.TabBtns[i] then
            local isShowRed = self._Control:CheckTaskCanRecvByTaskId(cfg.Id)
            self.TabBtns[i]:ShowReddot(isShowRed)
        end
    end
end
--endregion

--region Ui - BtnListener
function XUiGoldenMinerTask:AddListener()
    self:RegisterClickEvent(self.BtnBack, self.Close)
    self:RegisterClickEvent(self.BtnMainUi, function() XLuaUiManager.RunMain() end)
end
--endregion