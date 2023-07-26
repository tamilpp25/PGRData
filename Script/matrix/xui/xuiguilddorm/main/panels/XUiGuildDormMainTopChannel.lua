--=============
--
--=============
local XUiGuildDormMainTopChannel = XClass(nil, "XUiGuildDormMainTopChannel")

function XUiGuildDormMainTopChannel:Ctor(panel)
    XTool.InitUiObjectByUi(self, panel)
    XEventManager.AddEventListener(XEventId.EVENT_GUILD_DORM_PLAYER_ENTER, self.Refresh, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILD_DORM_PLAYER_EXIT, self.Refresh, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILD_DORM_RECONNECT_SUCCESS, self.Refresh, self)
end

function XUiGuildDormMainTopChannel:OnEnable()
    self:Refresh()
end

function XUiGuildDormMainTopChannel:SetShow()
    self.GameObject:SetActiveEx(true)
end

function XUiGuildDormMainTopChannel:SetHide()
    self.GameObject:SetActiveEx(false)
end

function XUiGuildDormMainTopChannel:Refresh()
    local guildDormManager = XDataCenter.GuildDormManager
    local currentRoomData = guildDormManager.GetCurrentRoom():GetRoomData()
    local currentChannelIndex = guildDormManager.GetCurrentChannelIndex()
    local currentChannelMemberCount = guildDormManager.GetMemberCountByChannelIndex(currentChannelIndex)
    self:ChangeChannel(currentChannelIndex)
    self:ChangeCurrentMemberNum(#guildDormManager.GetPlayerDatas())
    self:ChangeMaxMemberNum(currentRoomData:GetChannelMemberCount())
end

function XUiGuildDormMainTopChannel:ChangeChannel(channel)
    self.BtnChannel:SetNameByGroup(0, XUiHelper.GetText("GuildDormMainTopChannelName", channel))
end

function XUiGuildDormMainTopChannel:ChangeCurrentMemberNum(num)
    self.BtnChannel:SetNameByGroup(1, num)
end

function XUiGuildDormMainTopChannel:ChangeMaxMemberNum(num)
    self.BtnChannel:SetNameByGroup(2, "/" .. num)
end

function XUiGuildDormMainTopChannel:Dispose()
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILD_DORM_PLAYER_ENTER, self.Refresh, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILD_DORM_PLAYER_EXIT, self.Refresh, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILD_DORM_RECONNECT_SUCCESS, self.Refresh, self)
end

return XUiGuildDormMainTopChannel