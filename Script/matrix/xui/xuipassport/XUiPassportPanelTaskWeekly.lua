local XDynamicGridTask = require("XUi/XUiTask/XDynamicGridTask")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
---@field _Control XPassportControl
---@class XUiPassportPanelTaskWeekly:XUiNode
local XUiPassportPanelTaskWeekly = XClass(XUiNode, "XUiPassportPanelTaskWeekly")

--周任务
function XUiPassportPanelTaskWeekly:Ctor(ui, rootUi)
    self.RootUi = rootUi

    XUiHelper.RegisterClickEvent(self, self.BtnTongBlack, self.OnBtnTongBlackClick)

    self.DynamicTable = XDynamicTableNormal.New(self.SViewTask.transform)
    self.DynamicTable:SetProxy(XDynamicGridTask)
    self.DynamicTable:SetDelegate(self)

    self.GridTask.gameObject:SetActive(false)

    self:AddRedPointEvent(self.BtnTongBlack, self.OnCheckTaskRedPoint, self, { XRedPointConditions.Types.CONDITION_PASSPORT_TASK_WEEKLY_RED })
end

function XUiPassportPanelTaskWeekly:Refresh()
    if not self:IsShow() then
        return
    end

    local taskType = XEnumConst.PASSPORT.TASK_TYPE.WEEKLY

    self.Tasks = self._Control:GetPassportTask(taskType)
    self.DynamicTable:SetDataSource(self.Tasks)
    self.DynamicTable:ReloadDataASync()

    local passportTaskGroupId = self._Control:GetPassportTaskGroupIdByType(taskType)
    local currExp, totalExp = self._Control:GetPassportTaskExp(passportTaskGroupId)
    self.TxtDailyNumber.text = string.format("%s/%s", currExp, totalExp)

    self:UpdateTime()
end

function XUiPassportPanelTaskWeekly:UpdateTime()
    local passportTaskGroupId = self._Control:GetPassportTaskGroupIdByType(XEnumConst.PASSPORT.TASK_TYPE.WEEKLY)
    if not self:IsShow() or not XTool.IsNumberValid(passportTaskGroupId) then
        return
    end

    local timeId = self._Control:GetPassportTaskGroupTimeId(passportTaskGroupId)
    local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
    local nowServerTime = XTime.GetServerNowTimestamp()
    self.TxtDailyTime.text = XUiHelper.GetTime(endTime - nowServerTime, XUiHelper.TimeFormatType.PASSPORT)
end

function XUiPassportPanelTaskWeekly:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.Tasks[index]
        grid.RootUi = self.RootUi
        grid:ResetData(data)
    end
end

--一键领取
function XUiPassportPanelTaskWeekly:OnBtnTongBlackClick()
    self._Control:FinishMultiTaskRequest(XEnumConst.PASSPORT.TASK_TYPE.WEEKLY)
end

function XUiPassportPanelTaskWeekly:OnCheckTaskRedPoint(count)
    self.BtnTongBlack:ShowReddot(count >= 0)
end

function XUiPassportPanelTaskWeekly:Show()
    self.GameObject:SetActiveEx(true)
    self:Refresh()
end

function XUiPassportPanelTaskWeekly:Hide()
    self.GameObject:SetActiveEx(false)
end

function XUiPassportPanelTaskWeekly:IsShow()
    if XTool.UObjIsNil(self.GameObject) then
        return false
    end
    return self.GameObject.activeSelf
end

return XUiPassportPanelTaskWeekly