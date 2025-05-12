local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGuildViewChallenge = XClass(nil, "XUiGuildViewChallenge")
local XUiGridChallengeItem = require("XUi/XUiGuild/XUiChildItem/XUiGridChallengeItem")

function XUiGuildViewChallenge:Ctor(ui, uiRoot)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot

    XTool.InitUiObject(self)
    self:InitChildView()
end

function XUiGuildViewChallenge:OnEnable()
    self.GameObject:SetActiveEx(true)
    self:RefreshChallenges()
end

function XUiGuildViewChallenge:OnDisable()
    self.GameObject:SetActiveEx(false)
end

function XUiGuildViewChallenge:InitChildView()
    if not self.DynamicChallengeTable then
        self.DynamicChallengeTable = XDynamicTableNormal.New(self.PanelChallenge.gameObject)
        self.DynamicChallengeTable:SetProxy(XUiGridChallengeItem)
        self.DynamicChallengeTable:SetDelegate(self)
    end

end

function XUiGuildViewChallenge:OnViewDestroy()

end

function XUiGuildViewChallenge:RefreshChallenges()
    self.AllChallenges = XGuildConfig.GetGuildChallenges()
    self.DynamicChallengeTable:SetDataSource(self.AllChallenges)
    self.DynamicChallengeTable:ReloadDataASync()
end

function XUiGuildViewChallenge:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self.UiRoot)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.AllChallenges[index]
        if not data then return end
        grid:SetChallengeItem(data)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:OnChallengeClick(index)
    end
end

function XUiGuildViewChallenge:OnChallengeClick(index)
    -- 中途被踢出公会
    if not XDataCenter.GuildManager.IsJoinGuild() then
        XUiManager.TipMsg(CS.XTextManager.GetText("GuildKickOutByAdministor"))
        self.UiRoot:Close()
        return
    end

    -- 暂时这样处理
    local data = self.AllChallenges[index]
    if not data then return end
    if XDataCenter.GuildManager.IsGuildTourist() then
        XUiManager.TipMsg(CS.XTextManager.GetText("GuildTourstAccess"))
        return
    end
    if data.ChallengeType == XGuildConfig.GuildChallengeEnter.GuildTask then
        XLuaUiManager.Open("UiGuildTask")
    end
end

return XUiGuildViewChallenge