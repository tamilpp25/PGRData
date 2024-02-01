--######################## XUiGuildWarUpCharacter ########################
local XUiCommonTaskControl = require("XUi/XUiCommon/XUiCommonTaskControl")
local XUiGuildWarTask = XLuaUiManager.Register(XUiCommonTaskControl, "UiGuildWarTask")
local TaskGrid = require("XUi/XUiGuildWar/Task/XUiGuildWarTaskGrid")
function XUiGuildWarTask:OnAwake()
    XUiCommonTaskControl.Super.OnAwake(self)
    -- 任务列表
    self.CurrentTaskType = nil
    self.CurrentTasks = nil
    self.DynamicTable = XDynamicTableNormal.New(self.PanelTaskList)
    self.DynamicTable:SetProxy(TaskGrid, self)
    self.DynamicTable:SetDelegate(self)
    self.GridTask.gameObject:SetActiveEx(false)
    -- 注册按钮事件
    self:RegisterUiEvents()
    self.TabBtns = nil
    self.GuildWarManager = XDataCenter.GuildWarManager
    XUiHelper.NewPanelActivityAssetSafe({ XGuildWarConfig.ActivityPointItemId } ,self.PanelSpecialTool, self
        , { self.GuildWarManager.GetMaxActionPoint() })
end

function XUiGuildWarTask:CreateTabBtns()
    local result = {}
    self.TaskTypeDatas = self.GuildWarManager.GetAllShowedTaskTypeList()
    XUiHelper.RefreshCustomizedList(self.BtnTabGroup.transform, self.BtnTaskTab, #self.TaskTypeDatas, function(index, go)
        local button = go.transform:GetComponent("XUiButton")
        button:SetNameByGroup(0, self.TaskTypeDatas[index].Name)
        table.insert(result, button)
    end)
    return result
end

function XUiGuildWarTask:GetEndTime()
    return self.GuildWarManager.GetActivityEndTime()
end

function XUiGuildWarTask:HandleEndTimeFunc()
   self.GuildWarManager.OnActivityEndHandler()
end

function XUiGuildWarTask:GetTaskDataByTabIndex(index)
    return self.GuildWarManager.GetTaskList(self.TaskTypeDatas[index].TaskType)
end
--==================
--检查页签红点
--这里因为不走RedPointManager逻辑所以重写了通用方法
--==================
function XUiGuildWarTask:CheckBtnsRed()
    for index, btn in ipairs(self.TabBtns) do
        --这里任务类型和
        local isRed = XDataCenter.GuildWarManager.CheckTaskCanAchievedByType(self.TaskTypeDatas[index].TaskType)
        btn:ShowReddot(isRed)
    end
end

function XUiGuildWarTask:OnDataSourceChanged()
    -- if not self.CurrentTasks or #self.CurrentTasks == 0 then
    --     self.TextEmpty.gameObject:SetActiveEx(true)
    -- else
    --     self.TextEmpty.gameObject:SetActiveEx(false)
    -- end
end

return XUiGuildWarTask
