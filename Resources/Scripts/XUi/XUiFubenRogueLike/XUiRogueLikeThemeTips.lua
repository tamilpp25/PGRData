local XUiRogueLikeThemeTips = XLuaUiManager.Register(XLuaUi, "UiRogueLikeThemeTips")
local XUiGridTopicInfo = require("XUi/XUiFubenRogueLike/XUiGridTopicInfo")
local XUiDayTopicCharacter = require("XUi/XUiFubenRogueLike/XUiDayTopicCharacter")

function XUiRogueLikeThemeTips:OnAwake()
    self.GridHeadList = {}
    self.GridTopicList = {}
    self.BtnTanchuangClose.CallBack = function() self:OnBtnTanchuagnClose() end
    if self.BtnClose then
        self.BtnClose.CallBack = function() self:OnBtnTanchuagnClose() end
    end
    XEventManager.AddEventListener(XEventId.EVENT_ROGUELIKE_TEAMEFFECT_CHANGES, self.RefreshTeamEffect, self)
end

function XUiRogueLikeThemeTips:OnDestroy()
    self:StopCounter()
    XEventManager.RemoveEventListener(XEventId.EVENT_ROGUELIKE_TEAMEFFECT_CHANGES, self.RefreshTeamEffect, self)
end

function XUiRogueLikeThemeTips:RefreshTeamEffect()
    local teamEffectId = XDataCenter.FubenRogueLikeManager.GetTeamEffectId()
    if teamEffectId <= 0 then return end
    local teamEffectTemplate = XFubenRogueLikeConfig.GetTeamEffectTemplateById(teamEffectId)
    if not teamEffectTemplate then return end
    local dayBuffs = XDataCenter.FubenRogueLikeManager.GetRogueLikeDayBuffs()

    if XDataCenter.FubenRogueLikeManager.IsSectionPurgatory() then
        self.Text.gameObject:SetActiveEx(false)
        self.PanelThemeBuff.gameObject:SetActiveEx(false)
        self.PanelResetTime.gameObject:SetActiveEx(false)
    else
        self.Text.gameObject:SetActiveEx(true)
        self.PanelThemeBuff.gameObject:SetActiveEx(true)
        self.PanelResetTime.gameObject:SetActiveEx(true)
        -- 今日主题
        for i = 1, #dayBuffs do
            if not self.GridTopicList[i] then
                local ui = CS.UnityEngine.Object.Instantiate(self.GridThemeBuff.gameObject)
                ui.transform:SetParent(self.PanelThemeBuff, false)
                ui.gameObject:SetActiveEx(true)
                self.GridTopicList[i] = XUiGridTopicInfo.New(ui, self)
            end
            self.GridTopicList[i].GameObject:SetActiveEx(true)
            self.GridTopicList[i]:SetTopicInfo(dayBuffs[i])
        end
        for i = #dayBuffs + 1, #self.GridTopicList do
            self.GridTopicList[i].GameObject:SetActiveEx(false)
        end
    end
    

    -- 角色
    local characterInfos = XDataCenter.FubenRogueLikeManager.GetCharacterInfos()
    for i = 1, #characterInfos do
        local characterInfo = characterInfos[i]
        if not self.GridHeadList[i] then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridHead.gameObject)
            ui.transform:SetParent(self.PanelThemeHead, false)
            ui.gameObject:SetActiveEx(true)
            self.GridHeadList[i] = XUiDayTopicCharacter.New(ui, self)
        end
        self.GridHeadList[i].GameObject:SetActiveEx(true)
        self.GridHeadList[i]:SetTopicInfo(characterInfo)
    end
    -- 调换队长位置
    for i = #characterInfos + 1, #self.GridHeadList do
        self.GridHeadList[i].GameObject:SetActiveEx(false)
    end

    self:StartCounter()
end

function XUiRogueLikeThemeTips:OnStart()
    self:RefreshTeamEffect()
end

function XUiRogueLikeThemeTips:OnEnable()
    XDataCenter.FubenRogueLikeManager.CheckRogueLikeDayResetOnUi("UiRogueLikeThemeTips")
end

function XUiRogueLikeThemeTips:StartCounter()
    self:StopCounter()

    local now = XTime.GetServerNowTimestamp()
    local endTime = XDataCenter.FubenRogueLikeManager.GetDayRefreshTime()
    if not endTime then return end

    self.TxtResetTime.text = XUiHelper.GetTime(endTime - now, XUiHelper.TimeFormatType.ACTIVITY)
    if not XDataCenter.FubenRogueLikeManager.IsInActivity() then
        self.TxtResetTime.text = CS.XTextManager.GetText("RogueLikeOutOfDate")
    end

    self.CountTimer = XScheduleManager.ScheduleForever(
    function()
        now = XTime.GetServerNowTimestamp()
        if now > endTime then
            self:StopCounter()
            return
        end
        self.TxtResetTime.text = XUiHelper.GetTime(endTime - now, XUiHelper.TimeFormatType.ACTIVITY)
        if not XDataCenter.FubenRogueLikeManager.IsInActivity() then
            self.TxtResetTime.text = CS.XTextManager.GetText("RogueLikeOutOfDate")
        end
    end,
    XScheduleManager.SECOND,
    0
    )
end

function XUiRogueLikeThemeTips:StopCounter()
    if self.CountTimer ~= nil then
        XScheduleManager.UnSchedule(self.CountTimer)
        self.CountTimer = nil
    end
end

function XUiRogueLikeThemeTips:OnBtnTanchuagnClose()
    self:Close()
end