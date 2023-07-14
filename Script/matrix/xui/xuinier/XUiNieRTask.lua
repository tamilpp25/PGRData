local XUiNieRTask = XLuaUiManager.Register(XLuaUi, "UiNierTask")
local XUiPanelNieRTask = require("XUi/XUiNieR/XUiPanelNieRTask")
local XUiGridNieRTaskBtn = require("XUi/XUiNieR/XUiGridNieRTaskBtn")
local PANEL_INDEX = {
    Chapter1 = 1,
    Chapter2 = 2,
    Chapter3 = 3,
    Chapter4 = 4,
    RepeatChapter = 4,
}
function XUiNieRTask:OnAwake()
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)

    self.XUiPanelNieRTask = XUiPanelNieRTask.New(self.PanelTaskStory, self)

    self.DynamicTable = XDynamicTableNormal.New(self.PanelBtnDynamic)
    self.DynamicTable:SetProxy(XUiGridNieRTaskBtn)
    self.DynamicTable:SetDelegate(self)
end

function XUiNieRTask:OnStart(jumpId) 
    self.DefJumpId = jumpId
    XEventManager.AddEventListener(XEventId.EVENT_TASK_SYNC, self.ResetNierTaskNode, self)
end

function XUiNieRTask:OnEnable()
    self.LastSelGridIndex = 1
    self:ResetNierTaskNode()
end

function XUiNieRTask:ResetNierTaskNode()
    self.TaskList = XDataCenter.NieRManager.GetActivityNierTaskGroupList()
    self.DynamicTable:SetDataSource(self.TaskList)
    self.DynamicTable:ReloadDataASync()
   
    if next(self.TaskList) ~= nil and not self.DefJumpId then
        self:OnTaskBtnSelect(self.LastSelGridIndex)
    else
        local jumpIndex = self.LastSelGridIndex
        for index, info in ipairs(self.TaskList) do
            if info.TaskGroupId == self.DefJumpId then
                jumpIndex = index
            end
        end
        self.LastSelGridIndex = jumpIndex
        self:OnTaskBtnSelect(jumpIndex)
        self.DefJumpId = nil
    end
end

function XUiNieRTask:OnDisable()

end

function XUiNieRTask:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_TASK_SYNC, self.ResetNierTaskNode, self)
end

--动态列表事件
function XUiNieRTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.TaskList[index]
        grid:Refresh(data)
        if self.LastSelGridIndex == index then
            grid:IsSelect(true)
        else
            grid:IsSelect(false)
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        if self.LastSelGridIndex == index then return end
        local gridLast = self.DynamicTable:GetGridByIndex(self.LastSelGridIndex)
        if gridLast then
            gridLast:IsSelect(false)
        end
        grid:IsSelect(true)
        self.LastSelGridIndex = index
        self:OnTaskBtnSelect(index)
    end
end

function XUiNieRTask:OnTaskBtnSelect(index)
    local data = self.TaskList[index]
    local taskList = XDataCenter.NieRManager.GetActivityNierTaskByChapterId(data.TaskGroupId)
    if self.IsFirstAnimation == nil then
        self.IsFirstAnimation = true
    else
        self.IsFirstAnimation = false
    end
    XLog.Debug("OnTaskBtnSelect", self.IsFirstAnimation)
    self.XUiPanelNieRTask:UpdateTaskList(taskList, self.IsFirstAnimation)
    self:PlayAnimation("TaskStoryQieHuan")
end

function XUiNieRTask:OnBtnBackClick()
    self:Close()
end

function XUiNieRTask:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end
