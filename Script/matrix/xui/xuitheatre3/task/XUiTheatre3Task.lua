---@class XUiTheatre3Task : XLuaUi
---@field _Control XTheatre3Control
local XUiTheatre3Task = XLuaUiManager.Register(XLuaUi, "UiTheatre3Task")

function XUiTheatre3Task:OnAwake()
    self:RegisterUiEvents()
    self.GridTask.gameObject:SetActiveEx(false)
end

function XUiTheatre3Task:OnStart()
    --self.ItemId = XEnumConst.THEATRE3.Theatre3OutCoin
    --self.AssetPanel = XUiHelper.NewPanelActivityAssetSafe({ self.ItemId }, self.PanelSpecialTool, self, nil, handler(self, self.OnBtnClick))
    
    self:InitDynamicTable()
    self:InitLeftTabBtns()
end

function XUiTheatre3Task:OnEnable()
    self.BtnTabGroup:SelectIndex(self.SelectIndex or 1)
    self:RefreshRedPoint()
end

function XUiTheatre3Task:OnDestroy()
    --XDataCenter.ItemManager.RemoveCountUpdateListener(self.AssetPanel)
end

function XUiTheatre3Task:OnGetEvents()
    return { 
        XEventId.EVENT_FINISH_TASK,
    }
end

function XUiTheatre3Task:OnNotify(event, ...)
    if event == XEventId.EVENT_FINISH_TASK then
        self:SetupDynamicTable()
        self:RefreshRedPoint()
    end
end

function XUiTheatre3Task:InitLeftTabBtns()
    self.BtnTask.gameObject:SetActiveEx(false)

    self.TabBtns = {}
    local taskConfigIds = self._Control:GetTaskConfigIds()
    for index, id in pairs(taskConfigIds) do
        local tabBtn = index == 1 and self.BtnTask or XUiHelper.Instantiate(self.BtnTask, self.BtnContent)
        tabBtn:SetName(self._Control:GetTaskNameById(id))
        tabBtn.gameObject:SetActiveEx(true)
        table.insert(self.TabBtns, tabBtn)
    end
    
    self.BtnTabGroup:Init(self.TabBtns, function(index) self:OnSelectBtnTag(index) end)
    self.SelectIndex = 1
end

function XUiTheatre3Task:OnSelectBtnTag(index)
    self.SelectIndex = index
    self:SetupDynamicTable()
    self:PlayAnimation("QieHuan")
end

function XUiTheatre3Task:RefreshRedPoint()
    local taskConfigIds = self._Control:GetTaskConfigIds()
    local isShowRedPoint = false
    for index, id in pairs(taskConfigIds) do
        isShowRedPoint = self._Control:CheckTaskCanRewardByTaskId(id)
        self.TabBtns[index]:ShowReddot(isShowRedPoint)
    end
end

function XUiTheatre3Task:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelTaskStoryList)
    self.DynamicTable:SetProxy(XDynamicGridTask, self, nil, handler(self, self.OnClickTaskGrid))
    self.DynamicTable:SetDelegate(self)
end

function XUiTheatre3Task:SetupDynamicTable()
    self.DataList = self:GetTaskDataList()
    self.PanelNoneStoryTask.gameObject:SetActiveEx(XTool.IsTableEmpty(self.DataList))
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataASync()
end

function XUiTheatre3Task:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:ResetData(self.DataList[index])
        grid.BtnFinish.CallBack = function() self:OnBtnFinishClick(grid) end
    end
end

function XUiTheatre3Task:GetTaskDataList()
    local taskConfigIds = self._Control:GetTaskConfigIds()
    local taskConfigId = taskConfigIds[self.SelectIndex] or 1
    return self._Control:GetTaskDatas(taskConfigId)
end

function XUiTheatre3Task:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, self.OnBtnMainUiClick)
end

function XUiTheatre3Task:OnBtnBackClick()
    self:Close()
end

function XUiTheatre3Task:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiTheatre3Task:OnBtnClick(index)
    XLuaUiManager.Open("UiTheatre3Tips", self.ItemId)
end

function XUiTheatre3Task:OnClickTaskGrid(reward)
    XLuaUiManager.Open("UiTheatre3Tips", reward.TemplateId)
end

function XUiTheatre3Task:OnBtnFinishClick(taskGrid)
    XDataCenter.TaskManager.FinishTask(taskGrid.Data.Id, function(rewardGoodsList)
        XLuaUiManager.Open("UiTheatre3TipReward", rewardGoodsList)
    end)
end

return XUiTheatre3Task