--=============
--公会主界面公会信息按钮控件
--=============
local XUiGuildDormMainBtnInfo = XClass(nil, "XUi/XUiGuildDorm/Main/Panels/XUiGuildDormMainBtnInfo")

function XUiGuildDormMainBtnInfo:Ctor(panel)
    XTool.InitUiObjectByUi(self, panel)
    XEventManager.AddEventListener(XEventId.EVENT_GUILD_DATA_CHANGED, self.Refresh, self)
end

function XUiGuildDormMainBtnInfo:OnEnable()
    self:Refresh()
end

function XUiGuildDormMainBtnInfo:Refresh()
    self:ChangeGuildExpAmount(XDataCenter.GuildManager.GetGuildExpAmount())
    self:ChangeGuildName(XDataCenter.GuildManager.GetGuildName())
    self:ChangeGuildLevel(XDataCenter.GuildManager.GetGuildLevel())
    self:ChangeGuildIcon(XDataCenter.GuildManager.GetGuildIconId())
    self:ChangeGuildId(XDataCenter.GuildManager.GetGuildId())
end

function XUiGuildDormMainBtnInfo:ChangeGuildExpAmount(guildExpAmount)
    self.ImgProgress.fillAmount = guildExpAmount
end

function XUiGuildDormMainBtnInfo:ChangeGuildName(name)
    self.BtnInformation:SetNameByGroup(0, name)
end

function XUiGuildDormMainBtnInfo:ChangeGuildLevel(level)
    self.BtnInformation:SetNameByGroup(1, level)
end

function XUiGuildDormMainBtnInfo:ChangeGuildId(guildId)
    self.BtnInformation:SetNameByGroup(2, string.format("%08d",guildId))
end

function XUiGuildDormMainBtnInfo:ChangeGuildIcon(icon)
    self.BtnInformation:SetRawImage(icon)
end

function XUiGuildDormMainBtnInfo:SetShow()
    self.GameObject:SetActiveEx(true)
end

function XUiGuildDormMainBtnInfo:SetHide()
    self.GameObject:SetActiveEx(false)
end

function XUiGuildDormMainBtnInfo:Dispose()
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILD_DATA_CHANGED, self.Refresh, self)
end

return XUiGuildDormMainBtnInfo