---@class XUiTwoSideTowerTaskTwo : XLuaUi
---@field _Control XTwoSideTowerControl
local XUiTwoSideTowerTaskTwo = XLuaUiManager.Register(XLuaUi, "UiTwoSideTowerTaskTwo")

function XUiTwoSideTowerTaskTwo:OnAwake()
    self:RegisterUiEvents()
    self.PanelSpecialTool.gameObject:SetActiveEx(false)
    self.GridTask.gameObject:SetActiveEx(false)
    self.TagBtnList = {}
    self.GroupIdList = {}
end

function XUiTwoSideTowerTaskTwo:OnStart(data)
    self.PanelTaskTransform = self.PanelTaskStoryList:GetComponent("RectTransform")
    self:InitDynamicTable()
    self:InitButtonGroup(data)
    self:RefreshTaskRedPoint()
end

function XUiTwoSideTowerTaskTwo:OnGetEvents()
    return {
        XEventId.EVENT_FINISH_TASK,
    }
end

function XUiTwoSideTowerTaskTwo:OnNotify(event, ...)
    if event == XEventId.EVENT_FINISH_TASK then
        self:SetupDynamicTable()
        self:RefreshTaskRedPoint()
    end
end

function XUiTwoSideTowerTaskTwo:InitButtonGroup(data)
    if XTool.IsTableEmpty(data) then
        return
    end
    if table.nums(data) > 1 then
        for index, info in pairs(data) do
            local btn = XUiHelper.Instantiate(self.BtnFirst, self.BtnContent)
            btn.gameObject:SetActiveEx(true)
            btn:SetName(info.Name)
            self.TagBtnList[index] = btn
            self.GroupIdList[index] = info.GroupId
        end
        self.BtnTabGroup:Init(self.TagBtnList, function(index) self:OnSelectBtnTag(index) end)
        self.BtnTabGroup:SelectIndex(1)
    else
        self.CurGroupId = data[1].GroupId
        if self.PanelTaskTransform then
            self.PanelTaskTransform.offsetMin = CS.UnityEngine.Vector2(16, self.PanelTaskTransform.offsetMin.y)
        end
        self:SetupDynamicTable()
    end
end

function XUiTwoSideTowerTaskTwo:OnSelectBtnTag(index)
    if self.SelectIndex == index then
        return
    end
    self.SelectIndex = index
    self.CurGroupId = self.GroupIdList[index]
    self:SetupDynamicTable()
    self:PlayAnimation("TaskStoryQieHuan")
end

function XUiTwoSideTowerTaskTwo:RefreshTaskRedPoint()
    if XTool.IsTableEmpty(self.TagBtnList) then
        return
    end
    for index, btn in pairs(self.TagBtnList) do
        local groupId = self.GroupIdList[index]
        local taskRadPoint = self._Control:CheckTaskAchievedRedPoint({ groupId })
        btn:ShowReddot(taskRadPoint)
    end
end

function XUiTwoSideTowerTaskTwo:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelTaskStoryList)
    self.DynamicTable:SetProxy(XDynamicGridTask, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiTwoSideTowerTaskTwo:SetupDynamicTable()
    self.DataList = XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(self.CurGroupId)
    self.PanelNoneStoryTask.gameObject:SetActiveEx(XTool.IsTableEmpty(self.DataList))
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataASync(1)
end

function XUiTwoSideTowerTaskTwo:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:ResetData(self.DataList[index])
    end
end

function XUiTwoSideTowerTaskTwo:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, self.OnBtnMainUiClick)
end

function XUiTwoSideTowerTaskTwo:OnBtnBackClick()
    self:Close()
end

function XUiTwoSideTowerTaskTwo:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

return XUiTwoSideTowerTaskTwo
