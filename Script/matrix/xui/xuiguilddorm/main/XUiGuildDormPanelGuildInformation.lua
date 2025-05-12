--============
--公会信息面板
--============
local XUiGuildDormPanelGuildInformation = XClass(nil, "XUiGuildDormPanelGuildInformation")
local XUiGuildDormPanelGITopInfo = require("XUi/XUiGuildDorm/Main/XUiGuildDormPanelGITopInfo")
local XUiGuildDormGuildSetting = require("XUi/XUiGuildDorm/Main/XUiGuildDormMainGuildSetting")

function XUiGuildDormPanelGuildInformation:Ctor(panel, data)
    XTool.InitUiObjectByUi(self, panel)
    -- 设置面板 ---
    self.BtnTanchuangCloseBig.CallBack = function() self:Hide() end
    self.BtnAnnounce.CallBack = function() self:OnClickBtnAnnounce() end
    self.BtnInterCom.CallBack = function() self:OnClickBtnInterCom() end
    self.BtnRanking.CallBack = function() self:OnClickBtnRanking() end
    self.BtnJournal.CallBack = function() self:OnClickBtnJournal() end
    self.BtnDeclaration.CallBack = function() self:OnClickBtnDeclaration() end
    self.BtnTabMember.CallBack = function() self:OnClickBtnTabMember() end
    self.BtnTabChallenge.CallBack = function() self:OnClickBtnTabChallenge() end
    self.BtnTabGift.CallBack = function() self:OnClickBtnTabGift() end
    self.BtnAdministration.CallBack = function() self:OnClickAdministration() end
    --self:InitEventListeners()
    self.UiPanelTopInfo = XUiGuildDormPanelGITopInfo.New(self.PanelTopInfo)
    self.UiGuildSetting = XUiGuildDormGuildSetting.New(self.PanelGuildSetting)
    self:Refresh()
end

function XUiGuildDormPanelGuildInformation:InitEventListeners()
    if self.AddEventFlag then return end
    XEventManager.AddEventListener(XEventId.EVENT_GUILD_MEMBERCOUNT_CHANGED, self.RefreshBtnTabMember, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILD_DATA_CHANGED, self.Refresh, self)
    self.RedPointID = XRedPointManager.AddRedPointEvent(self.BtnAdministration, self.SetBtnAdministrationRed, self, { XRedPointConditions.Types.CONDITION_GUILD_APPLYLIST })
    self.AddEventFlag = true
end

function XUiGuildDormPanelGuildInformation:RemoveEventListeners()
    if not self.AddEventFlag then return end
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILD_MEMBERCOUNT_CHANGED, self.RefreshBtnTabMember, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILD_DATA_CHANGED, self.Refresh, self)
    XRedPointManager.RemoveRedPointEvent(self.RedPointID)
    self.AddEventFlag = false
end

function XUiGuildDormPanelGuildInformation:Refresh()
    self:RefreshAnnounceText()
    self:RefreshInterCommu()
    self:RefreshBtnTabMember()
    self:RefreshBtnTabChallenge()
    self.UiPanelTopInfo:Refresh()
end

function XUiGuildDormPanelGuildInformation:OnClickBtnAnnounce()
    XLuaUiManager.Open("UiGuildInformation", XGuildConfig.InformationType.Announcement)
end

function XUiGuildDormPanelGuildInformation:OnClickBtnInterCom()
    XLuaUiManager.Open("UiGuildInformation", XGuildConfig.InformationType.InternalCommunication)
end

function XUiGuildDormPanelGuildInformation:OnClickBtnRanking()
    XLuaUiManager.Open("UiGuildRankingListSwitch")
end

function XUiGuildDormPanelGuildInformation:OnClickBtnJournal()
    XLuaUiManager.Open("UiGuildLog")
end

function XUiGuildDormPanelGuildInformation:OnClickBtnDeclaration()
    XLuaUiManager.Open("UiGuildWelcomeWord")
end

function XUiGuildDormPanelGuildInformation:RefreshBtnTabMember()
    local curCount = XDataCenter.GuildManager.GetOnlineMemberCount()
    self.BtnTabMember:SetNameByGroup(1, CSXTextManagerGetText("GuildMemberOnlineCount", curCount))
end

function XUiGuildDormPanelGuildInformation:OnClickBtnTabMember()
    local guildId = XDataCenter.GuildManager.GetGuildId()
    local roomData = XDataCenter.GuildDormManager.GetCurrentRoom():GetRoomData()
    local now = XTime.GetServerNowTimestamp()
    if now - roomData.LastRequestMember >= XGuildDormConfig.RequestMemberGap then
        roomData.LastRequestMember = now
        XDataCenter.GuildManager.GetGuildMembers(guildId, function()
                XLuaUiManager.Open("UiGuildRongyu")
            end)
    else
        XLuaUiManager.Open("UiGuildRongyu")
    end
end

function XUiGuildDormPanelGuildInformation:RefreshBtnTabChallenge()
    self.BtnTabChallenge:ShowReddot(XDataCenter.GuildBossManager.IsReward())
    local timeLeft = XDataCenter.GuildManager.GuildBossEndTime() - XTime.GetServerNowTimestamp()
    if timeLeft < 0 then
        timeLeft = 0
    end
    local timeStr = XUiHelper.GetTime(timeLeft, XUiHelper.TimeFormatType.MAINBATTERY)
    self.BtnTabChallenge:SetNameByGroup(1, CS.XTextManager.GetText("GuildBossCountDown", timeStr))
end

function XUiGuildDormPanelGuildInformation:OnClickBtnTabChallenge()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.GuildBoss) then
        return
    end
    XDataCenter.GuildBossManager.OpenGuildBossHall()
end

function XUiGuildDormPanelGuildInformation:OnClickBtnTabGift()
    XLuaUiManager.Open("UiGuildPanelWelfare")
end

function XUiGuildDormPanelGuildInformation:OnClickAdministration()
    self.UiGuildSetting:Show()
end

function XUiGuildDormPanelGuildInformation:SetBtnAdministrationRed(count)
    self.BtnAdministration:ShowReddot(count >= 0)
end

function XUiGuildDormPanelGuildInformation:RefreshAnnounceText()
    self.TxtAnnounce.text = XDataCenter.GuildManager.GetGuildDeclaration()
end

function XUiGuildDormPanelGuildInformation:RefreshInterCommu()
    local notice = XDataCenter.GuildManager.GetGuildInterCom()
    if notice == nil or notice == "" then
        self.TxtInterCom.text = CS.XTextManager.GetText("GuildInterComDes")
    else
        self.TxtInterCom.text = notice
    end
end

function XUiGuildDormPanelGuildInformation:Show(hideCb)
    self.HideCallback = hideCb
    self.GameObject:SetActiveEx(true)
    self:InitEventListeners()
    XDataCenter.UiPcManager.OnUiEnable(self, "Hide")
end

function XUiGuildDormPanelGuildInformation:Hide()
    self.GameObject:SetActiveEx(false)
    self:RemoveEventListeners()
    if self.HideCallback then
        self.HideCallback()
    end
    XDataCenter.UiPcManager.OnUiDisableAbandoned(true, self)
end

function XUiGuildDormPanelGuildInformation:OnEnable()
    self:Refresh()
end

function XUiGuildDormPanelGuildInformation:Dispose()
    self:RemoveEventListeners()
    self.UiPanelTopInfo:Dispose()
end

return XUiGuildDormPanelGuildInformation