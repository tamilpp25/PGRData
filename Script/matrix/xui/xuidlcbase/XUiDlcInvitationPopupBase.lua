---@class XUiDlcInvitationPopupBase : XLuaUi
local XUiDlcInvitationPopupBase = XClass(XLuaUi, "XUiDlcInvitationPopupBase")

local MenuType = {
    Main = 1,
    Second = 2,
    Calendar = 3,
}

function XUiDlcInvitationPopupBase:RegisterAutoClose()
    self:SetAutoCloseInfo(self:GetAutoCloseTime(), Handler(self, self.AutoCloseHandler))
end

function XUiDlcInvitationPopupBase:GetAutoCloseTime()
    return XTime.GetServerNowTimestamp() + XMVCA.XDlcRoom:GetInviteShowTime()
end

function XUiDlcInvitationPopupBase:AutoCloseHandler(isClose)
    if isClose then
        self:Close()
    end
end

function XUiDlcInvitationPopupBase:Close()
    XLuaUiManager.CloseWithCallback(self.Name, function()
        XMVCA.XDlcRoom:CheckReceiveInvitation(true)
    end)
end

-- region 事件

function XUiDlcInvitationPopupBase:OnHideInvite()
    self:SetPanelActive(false)
end

function XUiDlcInvitationPopupBase:OnSceneAnimationPlayBegin()
    self:SetPanelActive(false)
end

function XUiDlcInvitationPopupBase:OnSceneAnimationPlayBreak()
    self:CheckShowPanel()
end

function XUiDlcInvitationPopupBase:OnSceneAnimationPlayEnd()
    self:CheckShowPanel()
end

function XUiDlcInvitationPopupBase:OnMainRightMenuStatusChange(menuType)
    self:SetPanelActive(menuType == MenuType.Main)
end

function XUiDlcInvitationPopupBase:OnFunctionEventEnd()
    self:CheckShowPanel()
end

-- endregion

function XUiDlcInvitationPopupBase:RegisterListeners()
    XEventManager.AddEventListener(XEventId.EVENT_DLC_HIDE_INVITE, self.OnHideInvite, self)
    XEventManager.AddEventListener(XEventId.EVENT_MAIN_SCENE_ANIM_PLAY_BEGIN, self.OnSceneAnimationPlayBegin, self)
    XEventManager.AddEventListener(XEventId.EVENT_MAIN_SCENE_ANIM_PLAY_BREAK, self.OnSceneAnimationPlayBreak, self)
    XEventManager.AddEventListener(XEventId.EVENT_MAIN_SCENE_ANIM_PLAY_END, self.OnSceneAnimationPlayEnd, self)
    XEventManager.AddEventListener(XEventId.EVENT_MAINUI_RIGHT_MENU_STATUS_CHANGE, self.OnMainRightMenuStatusChange,
        self)
    XEventManager.AddEventListener(XEventId.EVENT_FUNCTION_EVENT_END, self.OnFunctionEventEnd, self)
    XEventManager.AddEventListener(XEventId.EVENT_DLC_CLEAR_INVITE, self.Close, self)
end

function XUiDlcInvitationPopupBase:RemoveListeners()
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_HIDE_INVITE, self.OnHideInvite, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_MAIN_SCENE_ANIM_PLAY_BEGIN, self.OnSceneAnimationPlayBegin, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_MAIN_SCENE_ANIM_PLAY_BREAK, self.OnSceneAnimationPlayBreak, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_MAIN_SCENE_ANIM_PLAY_END, self.OnSceneAnimationPlayEnd, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_MAINUI_RIGHT_MENU_STATUS_CHANGE, self.OnMainRightMenuStatusChange,
        self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FUNCTION_EVENT_END, self.OnFunctionEventEnd, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_CLEAR_INVITE, self.Close, self)
end

function XUiDlcInvitationPopupBase:OnEnable()
    self:RegisterListeners()
end

function XUiDlcInvitationPopupBase:OnDisable()
    self:RemoveListeners()
end

function XUiDlcInvitationPopupBase:OnGetEvents()
    return {
        CS.XEventId.EVENT_UI_ENABLE,
        CS.XEventId.EVENT_UI_DISABLE,
        XEventId.EVENT_MOVIE_BEGIN,
        XEventId.EVENT_MOVIE_END,
        CS.XEventId.EVENT_VIDEO_ACTION_PLAY,
        CS.XEventId.EVENT_VIDEO_ACTION_STOP,
        XEventId.EVENT_CHAT_CLOSE,
    }
end

function XUiDlcInvitationPopupBase:OnNotify(event, ...)
    -- 剧情相关、录像相关
    if event == XEventId.EVENT_MOVIE_BEGIN or event == XEventId.EVENT_MOVIE_END or event
        == CS.XEventId.EVENT_VIDEO_ACTION_PLAY or event == CS.XEventId.EVENT_VIDEO_ACTION_STOP then
        self:CheckShowPanel()
        return
    end

    local args = {
        ...,
    }

    if event == CS.XEventId.EVENT_UI_ENABLE or event == CS.XEventId.EVENT_UI_DISABLE then
        if args[1] and args[1].UiData then
            local uiObject = args[1]
            local uiType = uiObject.UiData.UiType
            local uiName = uiObject.UiData.UiName

            if not (uiType == CS.XUiType.Normal or uiType == CS.XUiType.NormalPopup) then
                return
            end
            if uiName == self.Name then
                return
            end
            self:CheckShowPanel()
        end
    end
end

function XUiDlcInvitationPopupBase:CheckShowPanel()
    if CS.XFight.IsRunning or XDataCenter.MovieManager.IsPlayingMovie()
        or XHomeSceneManager.IsInHomeScene() or XMVCA.XFavorability:CheckCurSceneAnimIsPlaying()
        or XDataCenter.FunctionEventManager.IsPlaying() then
        self:SetPanelActive(false)
    else
        if XUiManager.CheckTopUi(CsXUiType.Normal, "UiMain") then
            local luaUi = XLuaUiManager.GetTopLuaUi("UiMain")
            local show = false

            if luaUi and luaUi.IsShowMain then
                show = luaUi:IsShowMain()
            end
            
            self:SetPanelActive(show)
        else
            self:SetPanelActive(false)
        end
    end
end

function XUiDlcInvitationPopupBase:SetPanelActive(isActive)
    self.GameObject:SetActiveEx(isActive)
end

return XUiDlcInvitationPopupBase
