local XDynamicGridTask = require("XUi/XUiTask/XDynamicGridTask")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
---@field _Control XPassportControl
---@class XUiPassportPanelTaskActivity:XUiNode
local XUiPassportPanelTaskActivity = XClass(XUiNode, "XUiPassportPanelTaskActivity")

--活动任务
function XUiPassportPanelTaskActivity:Ctor(ui, rootUi)
    self.RootUi = rootUi
    
    XUiHelper.RegisterClickEvent(self, self.BtnTongBlack, self.OnBtnTongBlackClick)

    self.DynamicTable = XDynamicTableNormal.New(self.SViewTask.transform)
    self.DynamicTable:SetProxy(XDynamicGridTask, self)
    self.DynamicTable:SetDelegate(self)

    self.GridTask.gameObject:SetActive(false)

    self:AddRedPointEvent(self.BtnTongBlack, self.OnCheckTaskRedPoint, self, { XRedPointConditions.Types.CONDITION_PASSPORT_TASK_ACTIVITY_RED })
end

function XUiPassportPanelTaskActivity:Refresh()
    if not self:IsShow() then
        return
    end

    self.Tasks = self._Control:GetPassportTask(XEnumConst.PASSPORT.TASK_TYPE.ACTIVITY)
    self.DynamicTable:SetDataSource(self.Tasks)
    self.DynamicTable:ReloadDataSync()

    local clearTaskCount = self._Control:GetClearTaskCount(XEnumConst.PASSPORT.TASK_TYPE.ACTIVITY)
    local taskTotalCount = self._Control:GetPassportBPTaskTotalCount()
    self.TxtDailyNumber.text = string.format("%s/%s", clearTaskCount, taskTotalCount)
end

function XUiPassportPanelTaskActivity:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.Tasks[index]
        grid.RootUi = self.RootUi
        grid:ResetData(data)
    end
end

--一键领取
function XUiPassportPanelTaskActivity:OnBtnTongBlackClick()
    self._Control:FinishMultiTaskRequest(XEnumConst.PASSPORT.TASK_TYPE.ACTIVITY)
end

function XUiPassportPanelTaskActivity:OnCheckTaskRedPoint(count)
    self.BtnTongBlack:ShowReddot(count >= 0)
end

function XUiPassportPanelTaskActivity:Show()
    self.GameObject:SetActiveEx(true)
    self:Refresh()
end

function XUiPassportPanelTaskActivity:Hide()
    self.GameObject:SetActiveEx(false)
end

function XUiPassportPanelTaskActivity:IsShow()
    if XTool.UObjIsNil(self.GameObject) then
        return false
    end
    return self.GameObject.activeSelf
end

return XUiPassportPanelTaskActivity