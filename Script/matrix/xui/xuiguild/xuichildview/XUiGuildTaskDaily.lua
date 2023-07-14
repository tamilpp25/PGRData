local XUiGuildTaskDaily = XClass(nil, "XUiGuildTaskDaily")
local XUiGridGuildTaskItem = require("XUi/XUiGuild/XUiChildItem/XUiGridGuildTaskItem")

function XUiGuildTaskDaily:Ctor(ui, uiRoot)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot

    XTool.InitUiObject(self)
    self:InitChildView()
end
-- PaneDlailyTask
-- PanelGradeContent
-- PaneTaskCompleted

function XUiGuildTaskDaily:InitChildView()
    self.DynamicTable = XDynamicTableNormal.New(self.PaneDlailyTask.gameObject)
    self.DynamicTable:SetProxy(XUiGridGuildTaskItem)
    self.DynamicTable:SetDelegate(self)

end

function XUiGuildTaskDaily:UpdateTasks()
    self.GuildTasks = XDataCenter.GuildManager.GetSortedGuildDailyTasks()

    self.DynamicTable:SetDataSource(self.GuildTasks)
    self.DynamicTable:ReloadDataASync()
    self.PaneTaskCompleted.gameObject:SetActiveEx(#self.GuildTasks <= 0)
end

function XUiGuildTaskDaily:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self.UiRoot)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.GuildTasks[index]
        if not data then return end
        grid:SetItemData(data)
    end
end

return XUiGuildTaskDaily