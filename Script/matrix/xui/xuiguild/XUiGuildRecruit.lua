local XUiGuildRecruit = XLuaUiManager.Register(XLuaUi, "UiGuildRecruit")
local XUiGuildEnlistRecruit = require("XUi/XUiGuild/XUiChildView/XUiGuildEnlistRecruit")
local XUiGuildEnlistNews = require("XUi/XUiGuild/XUiChildView/XUiGuildEnlistNews")


function XUiGuildRecruit:OnAwake()
    self:InitTaskView()
end

function XUiGuildRecruit:InitTaskView()
    self.GuildAllEnlist = {}
    self.GuildAllEnlist[XGuildConfig.EnlistType.Recruit] = XUiGuildEnlistRecruit.New(self.PanelRecruit, self)
    self.GuildAllEnlist[XGuildConfig.EnlistType.News] = XUiGuildEnlistNews.New(self.PanelNews, self)

    self.BtnEnlistTabs = {}
    table.insert(self.BtnEnlistTabs, self.BtnTabRecruit)
    table.insert(self.BtnEnlistTabs, self.BtnTabNews)

    self.PanelTab:Init(self.BtnEnlistTabs, function(index) self:OnGuildTaskTabClick(index) end)
    self.BtnTanchuangClose.CallBack = function() self:OnBtnCloseClick() end
    self:AddRedPointEvent(self.Red, self.RefreshApplyList, self, { XRedPointConditions.Types.CONDITION_GUILD_APPLYLIST })
end

function XUiGuildRecruit:RefreshApplyList(count)
    self.Red.gameObject:SetActiveEx(count >= 0)
end

function XUiGuildRecruit:OnStart(defaultType)
    self.PanelTab:SelectIndex(defaultType or XGuildConfig.EnlistType.News)
end

function XUiGuildRecruit:OnDestroy()

end

function XUiGuildRecruit:OnGuildTaskTabClick(index)
    if self.LastSelect and self.LastSelect == index then
        return
    end
    self.LastSelect = index
    self.PanelRecruit.gameObject:SetActiveEx(index == XGuildConfig.EnlistType.Recruit)
    local isHandleApplyList = index == XGuildConfig.EnlistType.News
    self.PanelNews.gameObject:SetActiveEx(isHandleApplyList)

    if self.GuildAllEnlist[index] then
        self.GuildAllEnlist[index]:UpdateEnlists()
    end

    if isHandleApplyList then
        XDataCenter.GuildManager.ResetApplyMemberList()
    end
end

function XUiGuildRecruit:OnBtnCloseClick()
    self:Close()
end



