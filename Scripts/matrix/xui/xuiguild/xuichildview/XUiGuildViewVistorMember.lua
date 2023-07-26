local XUiGuildViewVistorMember = XClass(nil, "XUiGuildViewVistorMember")
local XUiGridMemberVistorItem = require("XUi/XUiGuild/XUiChildItem/XUiGridMemberVistorItem")

function XUiGuildViewVistorMember:Ctor(ui, uiRoot)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot
    XTool.InitUiObject(self)

    self:InitList()
end

function XUiGuildViewVistorMember:OnEnable()
    self.GameObject:SetActiveEx(true)
    self:OnRefreshData()
end

function XUiGuildViewVistorMember:OnDisable()
    self.GameObject:SetActiveEx(false)
end

function XUiGuildViewVistorMember:InitList()
    self.DynamicMemberTable = XDynamicTableNormal.New(self.MemberList.gameObject)
    self.DynamicMemberTable:SetProxy(XUiGridMemberVistorItem)
    self.DynamicMemberTable:SetDelegate(self)
end

function XUiGuildViewVistorMember:OnRefreshData()
    local guildId = XDataCenter.GuildManager.GetGuildId()
    local data = XDataCenter.GuildManager.GetVistorMemberList(guildId) or {}
    self.ListData = {}
    if next(data) then
        for _,v in pairs(data) do
            table.insert(self.ListData, v)
        end
        self.DynamicMemberTable:SetDataSource(self.ListData)
        self.DynamicMemberTable:ReloadDataASync()
    else
        XDataCenter.GuildManager.GetVistorGuildMembers(guildId,function()
            data = XDataCenter.GuildManager.GetVistorMemberList(guildId) or {}
            for _,v in pairs(data) do
                table.insert(self.ListData, v)
            end
            self.DynamicMemberTable:SetDataSource(self.ListData)
            self.DynamicMemberTable:ReloadDataASync()
        end)
    end
end

function XUiGuildViewVistorMember:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self.UiRoot)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:OnRefresh(self.ListData[index])
    -- elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
    end
end

return XUiGuildViewVistorMember