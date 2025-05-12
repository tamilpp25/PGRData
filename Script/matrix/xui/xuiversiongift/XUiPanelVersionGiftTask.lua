local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
--- 任务列表区域
---@class XUiPanelVersionGiftTask: XUiNode
---@field private _Control XVersionGiftControl
---@field BtnGroup XUiButtonGroup
local XUiPanelVersionGiftTask = XClass(XUiNode, 'XUiPanelVersionGiftTask')
local XUiGridVersionGiftTask = require('XUi/XUiVersionGift/XUiGridVersionGiftTask')

--region 生命周期

function XUiPanelVersionGiftTask:OnStart()
    self._StartRun = true
    self:InitDynamicTable()
    self:InitButtonGroup()
end

function XUiPanelVersionGiftTask:OnEnable()
    self:RefreshTabReddotShow()

    if self._StartRun then
        self._StartRun = false
        return
    end

    self:OnTabSelect(self._SelectIndex, true)
end

--endregion

--region 初始化

function XUiPanelVersionGiftTask:InitDynamicTable()
    self._DynamicTable = XDynamicTableNormal.New(self.SViewTask)
    self._DynamicTable:SetDelegate(self)
    self._DynamicTable:SetProxy(XUiGridVersionGiftTask, self, self.Parent, nil, function()
        self.Parent:RefreshProgressRewardShow()
        self:RefreshTabReddotShow()
        self:OnTabSelect(self._SelectIndex, true)
    end)
end

function XUiPanelVersionGiftTask:InitButtonGroup()
    self._Index2GroupId = {
        [1] = self._Control:GetActivityActivityTaskGroupId(),
        [2] = self._Control:GetActivityNormalTaskGroupId(),
        [3] = self._Control:GetActivityDailyTaskGroupId(),
    }

    self._GroupId2Index = {
        [self._Control:GetActivityActivityTaskGroupId()] = 1,
        [self._Control:GetActivityNormalTaskGroupId()] = 2,
        [self._Control:GetActivityDailyTaskGroupId()] = 3,
    }

    self._TabButtons = {
        self.BtnTabTask1,
        self.BtnTabTask2,
        self.BtnTabTask3,
    }

    self.BtnGroup:InitBtns(self._TabButtons, handler(self, self.OnTabSelect), 1)

    local finishableGroupId = XMVCA.XVersionGift:CheckAnyTaskGroupContainsFinishableTask()

    if XTool.IsNumberValid(finishableGroupId) then
        self.BtnGroup:SelectIndex(self._GroupId2Index[finishableGroupId] or 1)
    else
        self.BtnGroup:SelectIndex(1)
    end
    
    self.BtnTabTask1:SetNameByGroup(0, XUiHelper.GetText('VersionGiftActivityTaskTab'))
    self.BtnTabTask2:SetNameByGroup(0, XUiHelper.GetText('VersionGiftNormalTaskTab'))
    self.BtnTabTask3:SetNameByGroup(0, XUiHelper.GetText('VersionGiftDailyTaskTab'))

end

--endregion

--region 界面刷新

function XUiPanelVersionGiftTask:RefreshTaskListByGroupId(groupId)
    local taskDataList = self._Control:GetTaskDataListByGroupId(groupId)

    if XTool.IsTableEmpty(taskDataList) then
        self._DynamicTable:RecycleAllTableGrid()
        self.PanelNoneTask.gameObject:SetActiveEx(true)
    else
        self.PanelNoneTask.gameObject:SetActiveEx(false)
        self._DynamicTable:SetDataSource(taskDataList)
        self._DynamicTable:ReloadDataASync()
    end
end

function XUiPanelVersionGiftTask:RefreshTabReddotShow()
    for i, v in pairs(self._TabButtons) do
        v:ShowReddot(false)
    end

    local finishableGroupId = XMVCA.XVersionGift:CheckAnyTaskGroupContainsFinishableTask()

    if XTool.IsNumberValid(finishableGroupId) then
        local index = self._GroupId2Index[finishableGroupId]

        if XTool.IsNumberValid(index) then
            self._TabButtons[index]:ShowReddot(true)
        end
    end
end

--endregion

--region 事件

function XUiPanelVersionGiftTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local task = self._DynamicTable.DataSource[index]
        grid:Open()
        grid:ResetData(task)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RECYCLE then
        grid:Close()    
    end
end

function XUiPanelVersionGiftTask:OnTabSelect(index, force)
    if self._SelectIndex == index and not force then
        return
    end
    
    self._SelectIndex = index
    
    local groupId = self._Index2GroupId[self._SelectIndex]

    if XTool.IsNumberValid(groupId) then
        self:RefreshTaskListByGroupId(groupId)
    end
end

--endregion

return XUiPanelVersionGiftTask