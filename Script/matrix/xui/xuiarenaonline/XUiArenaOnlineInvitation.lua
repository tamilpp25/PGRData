local XUiArenaOnlineInvitation = XLuaUiManager.Register(XLuaUi, "UiArenaOnlineInvitation")
local AreaOnlineInvitationDes
local AreaOnlineShowTime

local RecheckOnDisableWnds = {
    ["UiChatServeMain"] = true,
    ["UiAnnouncement"] = true,
    ["UiUsePackage"] = true,
    ["UiBuyAsset"] = true,
}

function XUiArenaOnlineInvitation:OnAwake()
    self._ShowInvitationWnds = XArenaOnlineConfigs.GetBossOnlineInviteUi()
    
    AreaOnlineInvitationDes = CS.XTextManager.GetText("AreaOnlineInvitationDes")
    AreaOnlineShowTime = XArenaOnlineConfigs.ArenaOnlineShowTime

    self.BtnInvite.gameObject:SetActiveEx(false)
    self.BtnMainInvite.gameObject:SetActiveEx(false)

    self:AddListener()
    self.WndCount = 0 --用于记录需要显示的窗口的数量
end

function XUiArenaOnlineInvitation:OnStart()
    for k,_ in pairs(self._ShowInvitationWnds) do
        if XLuaUiManager.IsUiShow(k) then
            self.WndCount = self.WndCount + 1
        end
    end
    self:CheckShowInvitationButton()
end

function XUiArenaOnlineInvitation:OnEnable()
    self:TimerEvent()
    XEventManager.AddEventListener(XEventId.EVENT_CHAT_RECEIVE_PRIVATECHAT, self.OnPrivateChat, self)
    XEventManager.AddEventListener(XEventId.EVENT_BLACK_DATA_CHANGE, self.OnBlackDataChange, self)
    XEventManager.AddEventListener(XEventId.EVENT_ARENA_HIDE_INVITATION, self.HideInvitation, self)
end

function XUiArenaOnlineInvitation:OnGetEvents()
    return
    {   CS.XEventId.EVENT_UI_ENABLE,
        CS.XEventId.EVENT_UI_DISABLE,
        XEventId.EVENT_MOVIE_BEGIN,
        XEventId.EVENT_MOVIE_END,
        CS.XEventId.EVENT_VIDEO_ACTION_PLAY,
        CS.XEventId.EVENT_VIDEO_ACTION_STOP,
        XEventId.EVENT_CHAT_CLOSE,
        XEventId.EVENT_MAINUI_TERMINAL_STATUS_CHANGE
    }
end

function XUiArenaOnlineInvitation:OnNotify(evt, ...)

    --剧情相关、录像相关
    if evt == XEventId.EVENT_MOVIE_BEGIN 
            or evt == XEventId.EVENT_MOVIE_END 
            or evt == CS.XEventId.EVENT_VIDEO_ACTION_PLAY 
            or evt == CS.XEventId.EVENT_VIDEO_ACTION_STOP 
            or evt == XEventId.EVENT_MAINUI_TERMINAL_STATUS_CHANGE then
        self:CheckShowInvitationButton()
        return
    end

    local args = {...}
    
    if args[1] and args[1].UiData then
        local uiObject = args[1]
        
        local uiType = uiObject.UiData.UiType
        
        if not (uiType == CS.XUiType.Normal or uiType == CS.XUiType.NormalPopup) then
            return
        end
        
        local uiName = uiObject.UiData.UiName
        if uiName == self.Name then
            return
        end

        if self._ShowInvitationWnds[uiName] then
            if evt == CS.XEventId.EVENT_UI_ENABLE then
                self.WndCount = self.WndCount + 1
            elseif evt == CS.XEventId.EVENT_UI_DISABLE then
                self.WndCount = self.WndCount - 1
            end
        end

        if RecheckOnDisableWnds[uiName] then
            if evt == CS.XEventId.EVENT_UI_DISABLE then
                self:CheckShowInvitationButton()
            end
        end
    end
    
    --界面处理重新打开
    if evt == CS.XEventId.EVENT_UI_ENABLE then
        self:CheckShowInvitationButton()
    end
end

function XUiArenaOnlineInvitation:TimerEvent()
    if AreaOnlineShowTime < 0 then
        return
    end

    self.Timer = XScheduleManager.ScheduleOnce(function()
            self:Close()
            XScheduleManager.UnSchedule(self.Timer)
            self.Timer = nil
        end, AreaOnlineShowTime * 1000)
end

function XUiArenaOnlineInvitation:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_CHAT_RECEIVE_PRIVATECHAT, self.OnPrivateChat, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_BLACK_DATA_CHANGE, self.OnBlackDataChange, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ARENA_HIDE_INVITATION, self.HideInvitation, self)
end

function XUiArenaOnlineInvitation:OnDestroy()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiArenaOnlineInvitation:AddListener()
    self.BtnInvite.CallBack = function() self:OnBtnInviteClick() end
    self.BtnMainInvite.CallBack = function() self:OnBtnInviteClick() end
end

function XUiArenaOnlineInvitation:OnBtnInviteClick()
    self:Close()
    XUiManager.DialogTip("", AreaOnlineInvitationDes, XUiManager.DialogType.Normal, function ()
            XDataCenter.ArenaOnlineManager.ClearPrivateChatData()
        end,
        function()
            self:OnBtnSocialClick()
        end)
end

function XUiArenaOnlineInvitation:RefreshCount()
    local datas = XDataCenter.ArenaOnlineManager.GetPrivateChatData() or {}
    local count = #datas

    local text = count == 0 and "" or (count > 99 and "..." or count)
    self.TxtCount0.text = text
    self.TxtCount1.text = text
end

function XUiArenaOnlineInvitation:OnPrivateChat()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
    self:TimerEvent()
    self.Datas = XDataCenter.ArenaOnlineManager.GetPrivateChatData()
    self.Count = #self.Datas
    self:RefreshCount()
end

function XUiArenaOnlineInvitation:OnBtnSocialClick()
    XDataCenter.ArenaOnlineManager.ClearPrivateChatData()
    if XLuaUiManager.IsUiShow("UiSocial") then
        XLuaUiManager.PopThenOpen("UiSocial", function()
                XEventManager.DispatchEvent(XEventId.EVENT_FRIEND_OPEN_PRIVATE_VIEW, self.Datas[self.Count].SenderId)
            end)
    else
        XLuaUiManager.Open("UiSocial", function()
                XEventManager.DispatchEvent(XEventId.EVENT_FRIEND_OPEN_PRIVATE_VIEW, self.Datas[self.Count].SenderId)
            end)
    end

end

function XUiArenaOnlineInvitation:CheckShowInvitationButton()

    self.Datas = XDataCenter.ArenaOnlineManager.GetPrivateChatData()
    self.Count = #self.Datas
    
    if self.WndCount <= 0 or CS.XFight.IsRunning
        or XDataCenter.MovieManager.IsPlayingMovie() or
        XDataCenter.VideoManager.IsPlaying() or 
        XHomeSceneManager.IsInHomeScene() then
        self.BtnInvite.gameObject:SetActiveEx(false)
        self.BtnMainInvite.gameObject:SetActiveEx(false)
    else
        self:RefreshCount()
        if XLuaUiManager.IsUiShow("UiMain") then
            local anim = XLoginManager.IsFirstOpenMainUi() and "AnimEnable1" or "AnimEnable2"
            self.BtnInvite.gameObject:SetActiveEx(false)
            local luaUi = XLuaUiManager.GetTopLuaUi("UiMain")
            local show = true
            if luaUi and luaUi.IsShowTerminal then
                show = not luaUi:IsShowTerminal()
            end
            self.BtnMainInvite.gameObject:SetActiveEx(show)
            self:PlayAnimation(anim)
        else
            self.BtnInvite.gameObject:SetActiveEx(true)
            self.BtnMainInvite.gameObject:SetActiveEx(false)
            self:PlayAnimation("AnimEnable2")
        end
    end
end

function XUiArenaOnlineInvitation:OnBlackDataChange()
    local data = XDataCenter.ArenaOnlineManager.GetPrivateChatData()
    local count = #data
    if not XTool.IsNumberValid(count) then
        self:Close()
        return
    end
    self:OnPrivateChat()
end

function XUiArenaOnlineInvitation:HideInvitation()
    self.BtnInvite.gameObject:SetActiveEx(false)
    self.BtnMainInvite.gameObject:SetActiveEx(false)
end