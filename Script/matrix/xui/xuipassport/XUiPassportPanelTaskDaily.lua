local XUiPassportPanelTaskDaily = XClass(nil, "XUiPassportPanelTaskDaily")

--每日任务
function XUiPassportPanelTaskDaily:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)

    XUiHelper.RegisterClickEvent(self, self.BtnTongBlack, self.OnBtnTongBlackClick)

    self.DynamicTable = XDynamicTableNormal.New(self.SViewTask.transform)
    self.DynamicTable:SetProxy(XDynamicGridTask)
    self.DynamicTable:SetDelegate(self)

    self.GridTask.gameObject:SetActive(false)

    XRedPointManager.AddRedPointEvent(self.BtnTongBlack, self.OnCheckTaskRedPoint, self, { XRedPointConditions.Types.CONDITION_PASSPORT_TASK_DAILY_RED })
end

function XUiPassportPanelTaskDaily:Refresh()
    if not self:IsShow() then
        return
    end

    self.Tasks = XDataCenter.PassportManager.GetPassportTask(XPassportConfigs.TaskType.Daily)
    self.DynamicTable:SetDataSource(self.Tasks)
    self.DynamicTable:ReloadDataASync()
end

function XUiPassportPanelTaskDaily:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.Tasks[index]
        grid.RootUi = self.RootUi
        grid:ResetData(data)
    end
end

--一键领取
function XUiPassportPanelTaskDaily:OnBtnTongBlackClick()
    XDataCenter.PassportManager.FinishMultiTaskRequest(XPassportConfigs.TaskType.Daily)
end

function XUiPassportPanelTaskDaily:OnCheckTaskRedPoint(count)
    self.BtnTongBlack:ShowReddot(count >= 0)
end

function XUiPassportPanelTaskDaily:Show()
    self.GameObject:SetActiveEx(true)
    self:Refresh()
end

function XUiPassportPanelTaskDaily:Hide()
    self.GameObject:SetActiveEx(false)
end

function XUiPassportPanelTaskDaily:IsShow()
    if XTool.UObjIsNil(self.GameObject) then
        return false
    end
    return self.GameObject.activeSelf
end

return XUiPassportPanelTaskDaily