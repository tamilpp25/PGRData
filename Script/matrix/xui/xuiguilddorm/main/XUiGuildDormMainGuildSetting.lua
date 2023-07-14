--============
--公会设定
--============
local XUiGuildDormMainGuildSetting = XClass(nil, "XUiGuildDormMainGuildSetting")

function XUiGuildDormMainGuildSetting:Ctor(panel)
    XTool.InitUiObjectByUi(self, panel)
    self.BtnDarkCloseBg.CallBack = function() self:OnClickClose() end
    self.BtnGuildExitGuild.CallBack = function() self:OnClickExitGuild() end
    self.BtnGuildJob.CallBack = function() self:OnClickJob() end
    self.BtnGuildApplication.CallBack = function() self:OnClickApplication() end
    self.BtnGuildSetName.CallBack = function() self:OnClickSetName() end
    self.BtnGuildReport.CallBack = function() self:OnClickReport() end
end

function XUiGuildDormMainGuildSetting:OnClickClose()
    self:Hide()
end

function XUiGuildDormMainGuildSetting:OnClickExitGuild()
    self:Hide()
    local isLeader = XDataCenter.GuildManager.IsGuildLeader()
    if isLeader then
        local memberCount = XDataCenter.GuildManager.GetMemberCount()
        if memberCount > 1 then
            XUiManager.TipMsg(CS.XTextManager.GetText("GuildQuitRemovePosition"))
            return
        else
            local title = CS.XTextManager.GetText("GuildDialogTitle")
            local content = CS.XTextManager.GetText("GuildQuitLastMember")
            XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, function()
                end, function()
                    XDataCenter.GuildManager.QuitGuild(function()
                            if XLuaUiManager.IsUiShow("UiGuildDormMain") then
                                XLuaUiManager.RunMain()
                            end
                        end)
                end)
        end
    else
        local title = CS.XTextManager.GetText("GuildDialogTitle")
        local content = CS.XTextManager.GetText("GuildQuitMemberQuit")
        XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, function()
            end, function()
                XDataCenter.GuildManager.QuitGuild(function()
                        if XLuaUiManager.IsUiShow("UiGuildDormMain") then
                            XLuaUiManager.RunMain()
                        end
                    end)
            end)
    end
end

function XUiGuildDormMainGuildSetting:OnClickJob()
    XLuaUiManager.Open("UiGuildCustomName")
    self:Hide()
end

function XUiGuildDormMainGuildSetting:OnClickApplication()
    local currentPageNo = XDataCenter.GuildManager.GetRecommendPageNo()
    XDataCenter.GuildManager.GuildRecruitRecommendRequest(currentPageNo, function()
            XLuaUiManager.Open("UiGuildRecruit", XGuildConfig.EnlistType.News)
            self:Hide()
        end)
end

function XUiGuildDormMainGuildSetting:OnClickSetName()
    if not XDataCenter.GuildManager.IsGuildLeader() then
        local leaderName = XDataCenter.GuildManager.GetRankNameByLevel(XGuildConfig.GuildRankLevel.Leader)
        XUiManager.TipMsg(CS.XTextManager.GetText("GuildNotAccessSetName", leaderName))
        return
    end
    XLuaUiManager.Open("UiGuildChangePosition", XGuildConfig.TipsType.SetName)
    self:Hide()
end

function XUiGuildDormMainGuildSetting:OnClickReport()
    local guildId = XDataCenter.GuildManager.GetGuildId()
    local titleName = XDataCenter.GuildManager.GetGuildName()
    local guildDesclaration = XDataCenter.GuildManager.GetGuildDeclaration()
    local guildInsideIntroduction = XDataCenter.GuildManager.GetGuildInterCom()
    local data = {Id = guildId, TitleName = titleName, GuildOuterIntroduction = guildDesclaration, GuildInsideIntroduction = guildInsideIntroduction}
    XLuaUiManager.Open("UiReport", data, nil, nil, XReportConfigs.EnterType.Guild)
end

function XUiGuildDormMainGuildSetting:RefreshApplyRed(count)
    self.BtnGuildApplication:ShowReddot(count >= 0)
end

function XUiGuildDormMainGuildSetting:Show()
    self.GameObject:SetActiveEx(true)
    XRedPointManager.AddRedPointEvent(self.BtnGuildApplication, self.RefreshApplyRed, self, { XRedPointConditions.Types.CONDITION_GUILD_APPLYLIST })
end

function XUiGuildDormMainGuildSetting:Hide()
    self.GameObject:SetActiveEx(false)
    XRedPointManager.RemoveRedPointEvent(self.BtnGuildApplication, self.RefreshApplyRed, self, { XRedPointConditions.Types.CONDITION_GUILD_APPLYLIST })
end

return XUiGuildDormMainGuildSetting