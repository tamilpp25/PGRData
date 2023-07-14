local XUiGuildTask = XLuaUiManager.Register(XLuaUi, "UiGuildTask")
local XUiGuildTaskDaily = require("XUi/XUiGuild/XUiChildView/XUiGuildTaskDaily")
local XUiGuildTaskMainly = require("XUi/XUiGuild/XUiChildView/XUiGuildTaskMainly")

function XUiGuildTask:OnAwake()
    self:InitTaskView()
end

function XUiGuildTask:InitTaskView()
    self.GuildAllTask = {}
    self.GuildAllTask[XGuildConfig.GuildTaskType.Daily] = XUiGuildTaskDaily.New(self.PaneDlailyTask, self)
    self.GuildAllTask[XGuildConfig.GuildTaskType.Mainly] = XUiGuildTaskMainly.New(self.PaneThreadTask, self)

    self.BtnTaskTabs = {}
    table.insert(self.BtnTaskTabs, self.BtnTabDlaily)
    table.insert(self.BtnTaskTabs, self.BtnTabThread)

    self.PanelTab:Init(self.BtnTaskTabs, function(index) self:OnGuildTaskTabClick(index) end)
    self.PanelTab:SelectIndex(XGuildConfig.GuildTaskType.Daily)
    self.BtnClose.CallBack = function() self:OnBtnCloseClick() end

    XRedPointManager.AddRedPointEvent(self.RedDaily, self.RefreshTaskDaily, self, { XRedPointConditions.Types.CONDITION_TASK_TYPE }, XDataCenter.TaskManager.TaskType.GuildDaily)
    XRedPointManager.AddRedPointEvent(self.RedMainly, self.RefresTaskMainly, self, { XRedPointConditions.Types.CONDITION_TASK_TYPE }, XDataCenter.TaskManager.TaskType.GuildMainly)
end

function XUiGuildTask:RefreshTaskDaily(count)
    self.RedDaily.gameObject:SetActiveEx(count >= 0)
end

function XUiGuildTask:RefresTaskMainly(count)
    self.RedMainly.gameObject:SetActiveEx(count >= 0)
end

function XUiGuildTask:OnStart()
end

function XUiGuildTask:OnEnable()

end

function XUiGuildTask:OnDisable()

end

function XUiGuildTask:OnDestroy()

end

function XUiGuildTask:OnGuildTaskTabClick(index)
    self.PaneDlailyTask.gameObject:SetActiveEx(index == XGuildConfig.GuildTaskType.Daily)
    self.PaneThreadTask.gameObject:SetActiveEx(index == XGuildConfig.GuildTaskType.Mainly)

    if self.GuildAllTask[index] then
        self.GuildAllTask[index]:UpdateTasks()
    end
end

function XUiGuildTask:OnBtnCloseClick()
    self:Close()
end



