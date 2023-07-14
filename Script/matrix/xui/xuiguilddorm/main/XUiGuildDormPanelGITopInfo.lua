--============
--XUiGuildDormPanelGuildInformation子面板
--============
local XUiGuildDormPanelGITopInfo = XClass(nil, "XUiGuildDormPanelGITopInfo")
local GuildBuildIntervalWhenMaxLevel = CS.XGame.Config:GetInt("GuildBuildIntervalWhenMaxLevel")
function XUiGuildDormPanelGITopInfo:Ctor(panel)
    XTool.InitUiObjectByUi(self, panel)
    
    self.BtnSetFace.gameObject:SetActiveEx(XDataCenter.GuildManager.IsGuildLeader())
    self.BtnSetFace.CallBack = function() self:OnClickBtnSetFace() end
    self.BtnGrade.CallBack = function() self:OnBtnGradeClick() end
    self.BtnCopy.CallBack = function() XTool.CopyToClipboard(self.TxtID.text) end
    XEventManager.AddEventListener(XEventId.EVENT_GUILD_DATA_CHANGED, self.Refresh, self)
end
--==========
--data : XUiGuildDormMainData
--==========
function XUiGuildDormPanelGITopInfo:Refresh()
    self.RImgGuildIcon:SetRawImage(XDataCenter.GuildManager.GetGuildIconId())
    self.TxtGuildName.text = XDataCenter.GuildManager.GetGuildName()
    self.TxtLeader.text = XDataCenter.GuildManager.GetGuildLeaderName()
    local guildLevel = XDataCenter.GuildManager.GetGuildLevel()
    local curBuild = XDataCenter.GuildManager.GetBuild()
    local guildLevelTemplate = XGuildConfig.GetGuildLevelDataBylevel(guildLevel)
    local guildId = XDataCenter.GuildManager.GetGuildId()
    self.TxtID.text = string.format("%08d",guildId)
    if XDataCenter.GuildManager.CheckAllTalentLevelMax() then
        local gloryLevel = XDataCenter.GuildManager.GetGloryLevel()
        self.TxtLvNum.text = string.format("<size=28>%d</size><color=#FFF400>(%d)</color>", guildLevel, gloryLevel)
    else
        self.TxtLvNum.text = string.format("<size=28>%d</size>", guildLevel)
    end
    if XDataCenter.GuildManager.IsGuildLevelMax(guildLevel) then
        -- 达到最高等级
        self.ImgProgress.fillAmount = curBuild * 1.0 / GuildBuildIntervalWhenMaxLevel
        self.TxtNum.text = string.format("<color=#008FFF>%s</color>/%s", tostring(curBuild), tostring(GuildBuildIntervalWhenMaxLevel))
    else
        -- 未到达最高等级
        self.TxtLvNum.text = guildLevel
        self.ImgProgress.fillAmount = curBuild * 1.0 / guildLevelTemplate.Build
        self.TxtNum.text = string.format("<color=#008FFF>%s</color>/%s", tostring(curBuild), tostring(guildLevelTemplate.Build))
    end
end

function XUiGuildDormPanelGITopInfo:OnClickBtnSetFace()
    XLuaUiManager.Open("UiGuildDormHeadPotrait")
end

function XUiGuildDormPanelGITopInfo:OnBtnGradeClick()
    if not XDataCenter.GuildManager.IsJoinGuild() then
        return
    end
    XLuaUiManager.Open("UiGuildGrade")

end

function XUiGuildDormPanelGITopInfo:Dispose()
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILD_DATA_CHANGED, self.Refresh, self)
end

return XUiGuildDormPanelGITopInfo