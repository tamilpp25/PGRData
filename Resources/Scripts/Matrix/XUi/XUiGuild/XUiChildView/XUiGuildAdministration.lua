local XUiGuildAdministration = XClass(nil, "XUiGuildAdministration")
local XUiGuildViewSetHeadPortrait = require("XUi/XUiGuild/XUiChildView/XUiGuildViewSetHeadPortrait")

function XUiGuildAdministration:Ctor(ui, uiRoot)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot

    XTool.InitUiObject(self)
    self.BtnRecruit.CallBack = function() self:OnBtnRecruitClick() end
    self:InitChildView()
end

function XUiGuildAdministration:UpdateGuildLevel()
    self.GuildLevel = XDataCenter.GuildManager.GetGuildLevel()
    self.GuildLevelTemplate = XGuildConfig.GetGuildLevelDataBylevel(self.GuildLevel)

    self:UpdateMainInfo()
end

function XUiGuildAdministration:UpdateMainInfo()
    -- 贡献度
    local build = XDataCenter.GuildManager.GetBuild()
    if self.TxtGuildLv then
        self.TxtGuildLv.text = self.GuildLevel
    end

    -- 刷新倒计时
    self.TextRefresh.text = CS.XTextManager.GetText("GuildMainRefreshCountDown", self:GetNextMonthRefreshTime())
    -- 贡献度/升级所需
    if not self.GuildLevelTemplate then
        -- local guildLevel = self.GuildLevel - 1
        -- local guildLevelTemplate = XGuildConfig.GetGuildLevelDataBylevel(self.GuildLevel)
        self.TextNum.text = "-/-"
        self.ImgProgress.fillAmount = 1
        self.BtnLevelUp:SetDisable(true, false)
    else
        if XDataCenter.GuildManager.IsGuildLevelMax(self.GuildLevel) then
            self.TextNum.text = "-/-"
        else
            self.TextNum.text = string.format("%d/%d", build, self.GuildLevelTemplate.Build)
        end
        self.ImgProgress.fillAmount = build / self.GuildLevelTemplate.Build
        if build >= self.GuildLevelTemplate.Build and (not XDataCenter.GuildManager.IsGuildLevelMax(self.GuildLevel)) then
            self.BtnLevelUp:SetDisable(false, true)
        else
            self.BtnLevelUp:SetDisable(true, false)
        end
    end
    -- 正常、紧急
    self.PanelNor.gameObject:SetActiveEx(true)
    self.ImgGuildIconNor:SetRawImage(XDataCenter.GuildManager.GetGuildIconId())
    self.TxtGuildNameNor.text = XDataCenter.GuildManager.GetGuildName()
    -- 日常维护
    self.TxtDailyCountNor.text = self.GuildLevelTemplate and self.GuildLevelTemplate.Contribution or 0
    self.ImgDailyIconNor:SetRawImage(XDataCenter.ItemManager.GetItemIcon(XGuildConfig.GuildContributeCoin))
    -- 紧急维护
    self.TxtUrgentCountNor.text = self.GuildLevelTemplate and self.GuildLevelTemplate.EmergencyMaintenance or 0
    self.ImgUrgentCountNor:SetRawImage(XDataCenter.ItemManager.GetItemIcon(XGuildConfig.GuildContributeCoin))
    self.TextGuildLvNor.text = XDataCenter.GuildManager.GetGuildLevel()


    self.PanelUrgent.gameObject:SetActiveEx(false)
    self.ImgGuildIconUrgent:SetRawImage(XDataCenter.GuildManager.GetGuildIconId())
    self.TxtGuildNameUrgent.text = XDataCenter.GuildManager.GetGuildName()
    -- 日常维护
    self.TxtDailyCountUrgent.text = self.GuildLevelTemplate and self.GuildLevelTemplate.Contribution or 0
    self.ImgDailyIconUrgent:SetRawImage(XDataCenter.ItemManager.GetItemIcon(XGuildConfig.GuildContributeCoin))
    -- 紧急维护
    self.TxtUrgentCountUrgent.text = self.GuildLevelTemplate and self.GuildLevelTemplate.EmergencyMaintenance or 0
    self.ImgUrgentCountUrgent:SetRawImage(XDataCenter.ItemManager.GetItemIcon(XGuildConfig.GuildContributeCoin))
    self.TextGuildLvUrgent.text = XDataCenter.GuildManager.GetGuildLevel()

    self.PanelUrgent.gameObject:SetActiveEx(XDataCenter.GuildManager.IsUrgentMaintainState())
    self.BtnAddUrgentCoin.gameObject:SetActiveEx(XDataCenter.GuildManager.IsUrgentMaintainState())
end

function XUiGuildAdministration:OnEnable()
    self.GameObject:SetActiveEx(true)
    self.GuildLevel = XDataCenter.GuildManager.GetGuildLevel()
    self.GuildLevelTemplate = XGuildConfig.GetGuildLevelDataBylevel(self.GuildLevel)

    self:UpdateMainInfo()

    -- 管理层才能做得操作
    self.BtnLevelUp.gameObject:SetActiveEx(XDataCenter.GuildManager.IsGuildAdminister())
    self.BtnOut.gameObject:SetActiveEx(not XDataCenter.GuildManager.IsGuildLeader())
    self.BtnRecruit.gameObject:SetActiveEx(XDataCenter.GuildManager.IsGuildAdminister())
    self.BtnCustom.gameObject:SetActiveEx(XDataCenter.GuildManager.IsGuildAdminister())

    self.IconCoinNor1:SetRawImage(XDataCenter.ItemManager.GetItemIcon(XGuildConfig.GuildCoin))
    self.IconCoinNor2:SetRawImage(XDataCenter.ItemManager.GetItemIcon(XGuildConfig.GuildContributeCoin))
    self.TxtCoinNor1.text = XDataCenter.ItemManager.GetCount(XGuildConfig.GuildCoin)
    self.TxtCoinNor2.text = XDataCenter.GuildManager.GetGuildContributeLeft()

    self.IconCoinUrgent1:SetRawImage(XDataCenter.ItemManager.GetItemIcon(XGuildConfig.GuildCoin))
    self.IconCoinUrgent2:SetRawImage(XDataCenter.ItemManager.GetItemIcon(XGuildConfig.GuildContributeCoin))
    self.TxtCoinUrgent1.text = XDataCenter.ItemManager.GetCount(XGuildConfig.GuildCoin)
    self.TxtCoinUrgent2.text = XDataCenter.GuildManager.GetGuildContributeLeft()

    self:StartBuildRefreshCounter()
    self:StartUrgentRefreshCounter()
end

-- 获取下次刷新时间
function XUiGuildAdministration:GetNextMonthRefreshTime()
    local now = XTime.GetServerNowTimestamp()
    local dateTime = CS.XDateUtil.GetGameDateTime(now)
    local monthZero = CS.XDateUtil.GetFirstDayOfThisMonth(dateTime):ToTimestamp()
    local firstDayOfMonthOfFive = monthZero + 5 * 60 * 60

    if now <= firstDayOfMonthOfFive then
        return XUiHelper.GetTime(firstDayOfMonthOfFive - now, XUiHelper.TimeFormatType.ACTIVITY)
    end

    local nextMonth = dateTime:AddMonths(1)
    local nextmonthZero = CS.XDateUtil.GetFirstDayOfThisMonth(nextMonth):ToTimestamp()
    local firstDayOfNextMonthOfFive = nextmonthZero + 5 * 60 * 60

    if now <= firstDayOfNextMonthOfFive then
        return XUiHelper.GetTime(firstDayOfNextMonthOfFive - now, XUiHelper.TimeFormatType.ACTIVITY)
    end

    return ""
end

function XUiGuildAdministration:OnDisable()
    self:StopBuildRefreshCounter()
    self:StopUrgentRefreshCounter()
    self.GameObject:SetActiveEx(false)
end

function XUiGuildAdministration:OnViewDestroy()
    self:StopBuildRefreshCounter()
    self:StopUrgentRefreshCounter()
end

function XUiGuildAdministration:InitChildView()
    self.BtnOut.CallBack = function() self:OnBtnOutClick() end
    self.BtnRecruit.CallBack = function() self:OnBtnRecruitClick() end
    self.BtnCustom.CallBack = function() self:OnBtnCustomClick() end
    self.BtnLevelUp.CallBack = function() self:OnBtnLevelUpClick() end

    self.BtnAddUrgentCoin.CallBack = function() self:OnBtnAddUrgentCoinClick() end
    self.BtnAddNor.CallBack = function() self:OnBtnAddNorClick() end
    self.BtnAddUrgent.CallBack = function() self:OnBtnAddUrgentClick() end
    self.BtnHeadIconClick.CallBack = function() self:OnBtnHeadIconClick() end

    XDataCenter.ItemManager.AddCountUpdateListener(XGuildConfig.GuildCoin, function()
        self.TxtCoinNor1.text = XDataCenter.ItemManager.GetCount(XGuildConfig.GuildCoin)
        self.TxtCoinUrgent1.text = XDataCenter.ItemManager.GetCount(XGuildConfig.GuildCoin)
    end, self.TxtCoinNor1)

    self.GuildViewSetHeadPortrait = XUiGuildViewSetHeadPortrait.New(self.PanelSetHeadPotrait,self)
    XRedPointManager.AddRedPointEvent(self.RedRecruit, self.RefreshApplyList, self, { XRedPointConditions.Types.CONDITION_GUILD_APPLYLIST })
end

function XUiGuildAdministration:RefreshApplyList(count)
    self.RedRecruit.gameObject:SetActiveEx(count >= 0)
end

function XUiGuildAdministration:RefreshGuildContribute()
    self.TxtCoinNor2.text = XDataCenter.GuildManager.GetGuildContributeLeft()
    self.TxtCoinUrgent2.text = XDataCenter.GuildManager.GetGuildContributeLeft()
end

function XUiGuildAdministration:StartUrgentRefreshCounter()
    self:StopUrgentRefreshCounter()
    local guildLevel = XDataCenter.GuildManager.GetGuildLevel()
    local guildLevelTemplate = XGuildConfig.GetGuildLevelDataBylevel(guildLevel)
    if not guildLevelTemplate then return end
    local beginTime = XDataCenter.GuildManager.GetEmergenceTime()
    local endTime = guildLevelTemplate.EmergencyDay * 23 * 60 * 60 + beginTime
    local now = XTime.GetServerNowTimestamp()
    self.TxtUrgentRefreshTime.text = XUiHelper.GetTime(endTime - now, XUiHelper.TimeFormatType.ACTIVITY)
    self.UrgentRefreshTimer = XScheduleManager.ScheduleForever(function()
        now = XTime.GetServerNowTimestamp()
        if now > endTime then
            self:StopUrgentRefreshCounter()
            return
        end
        self.TxtUrgentRefreshTime.text = XUiHelper.GetTime(endTime - now, XUiHelper.TimeFormatType.ACTIVITY)
    end, XScheduleManager.SECOND, 0)
end

function XUiGuildAdministration:StopUrgentRefreshCounter()
    if self.UrgentRefreshTimer then
        XScheduleManager.UnSchedule(self.UrgentRefreshTimer)
        self.UrgentRefreshTimer = nil
    end
end

function XUiGuildAdministration:StartBuildRefreshCounter()
    self:StopBuildRefreshCounter()
    self.BuildRefreshTimer = XScheduleManager.ScheduleForever(function()
        self.TextRefresh.text = CS.XTextManager.GetText("GuildMainRefreshCountDown", self:GetNextMonthRefreshTime())
    end, XScheduleManager.SECOND, 0)
end

function XUiGuildAdministration:StopBuildRefreshCounter()
    if self.BuildRefreshTimer then
        XScheduleManager.UnSchedule(self.BuildRefreshTimer)
        self.BuildRefreshTimer = nil
    end
end

-- 招募
function XUiGuildAdministration:OnBtnRecruitClick()
    if self:ChecKickOut() then return end
    if self:HasModifyAccess() then return end

    local currentPageNo = XDataCenter.GuildManager.GetRecommendPageNo()
    XDataCenter.GuildManager.GuildRecruitRecommendRequest(currentPageNo, function()
        XLuaUiManager.Open("UiGuildRecruit")
    end)
end

-- 退出
function XUiGuildAdministration:OnBtnOutClick()
    if self:ChecKickOut() then return end
    local title = CS.XTextManager.GetText("GuildDialogTitle")
    local content = CS.XTextManager.GetText("GuildQuitContent")

    XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, function()
    end, function()
        XDataCenter.GuildManager.QuitGuild(function()
            if XLuaUiManager.IsUiShow("UiGuildMain") then
                XLuaUiManager.Close("UiGuildMain")
            end
        end)
    end)
end

-- 升级
function XUiGuildAdministration:OnBtnLevelUpClick()
    if self:ChecKickOut() then return end
    if self:HasModifyAccess() then return end
    local guildLevel = XDataCenter.GuildManager.GetGuildLevel()
    local guildTemplate = XGuildConfig.GetGuildLevelDataBylevel(guildLevel)
    if not guildTemplate then return end
    local build = XDataCenter.GuildManager.GetBuild()
    if build < guildTemplate.Build then
        XUiManager.TipMsg(CS.XTextManager.GetText("GuildBuildNotEnough"))
        return
    end

    if not XDataCenter.GuildManager.IsGuildAdminister() then
        XUiManager.TipMsg(CS.XTextManager.GetText("GuildNotAccessLevelUp"))
        return
    end

    -- 已经到达最高级
    if XDataCenter.GuildManager.IsGuildLevelMax(guildLevel) then
        XUiManager.TipMsg(CS.XTextManager.GetText("GuildLevelIsMax"))
        return
    end

    local nextGuildLevel = guildLevel + 1
    local nextGuildTemplate = XGuildConfig.GetGuildLevelDataBylevel(nextGuildLevel)
    if not nextGuildTemplate then return end

    local title = CS.XTextManager.GetText("GuildDialogTitle")
    local content = CS.XTextManager.GetText("GuildLevelUpContent", nextGuildLevel, nextGuildTemplate.Contribution)
    local sureCallBack = function()
        XDataCenter.GuildManager.GuildLevelUp(function()
            self:OnEnable()
        end)
    end

    XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, function()
    end, sureCallBack)
end

-- 自定义职位
function XUiGuildAdministration:OnBtnCustomClick()
    if self:ChecKickOut() then return end
    if self:HasModifyAccess() then return end
   XLuaUiManager.Open("UiGuildCustomName")
end

-- 紧急维护
function XUiGuildAdministration:OnBtnAddUrgentCoinClick()
    -- 判断是否足够维护
    if self:ChecKickOut() then return end
    if self:HasModifyAccess() then return end

    local title = CS.XTextManager.GetText("GuildDialogTitle")
    local content = CS.XTextManager.GetText("GuildUrgentMaintain")

    XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, function()
    end, function()
        XDataCenter.GuildManager.GuildPayMaintain(function()
            self:OnEnable()
        end)
    end)

end

-- 增加贡献
function XUiGuildAdministration:OnBtnAddNorClick()
    if self:ChecKickOut() then return end
    XLuaUiManager.Open("UiBuyAsset", XGuildConfig.GuildContributeCoin, function()
    end)
end

-- 增加贡献
function XUiGuildAdministration:OnBtnAddUrgentClick()
    if self:ChecKickOut() then return end
    XLuaUiManager.Open("UiBuyAsset", XGuildConfig.GuildContributeCoin, function()
    end)
end

function XUiGuildAdministration:OnBtnHeadIconClick()
    self.PanelSetHeadPotrait.gameObject:SetActiveEx(true)
    self.GuildViewSetHeadPortrait:OnRefresh()
end

function XUiGuildAdministration:HasModifyAccess()
    if not XDataCenter.GuildManager.IsGuildAdminister() then
        XUiManager.TipMsg(CS.XTextManager.GetText("GuildNotAdministor"))
        return true
    end
    return false
end

function XUiGuildAdministration:ChecKickOut()
    if not XDataCenter.GuildManager.IsJoinGuild() then
        XUiManager.TipMsg(CS.XTextManager.GetText("GuildKickOutByAdministor"))
        self.UiRoot:Close()
        return true
    end
    return false
end

function XUiGuildAdministration:RecordGuildIconId(iconId)
    if self.CurGuildIconId ~= self.PreGuildIconId then
        local cfg = XGuildConfig.GetGuildHeadPortraitById(iconId)
        if cfg then
            self.ImgGuildIconNor:SetRawImage(cfg.Icon)
            self.PreGuildIconId = self.CurGuildIconId
        end
    end
end

return XUiGuildAdministration