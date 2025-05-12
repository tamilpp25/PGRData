local XUiPanelWebHtmlView = require("XUi/XUiCommonWebView/XUiPanelWebHtmlView")
---@class XUiLoginNotice : XLuaUi
---@field WebHtmlView XUiPanelWebHtmlView
local XUiLoginNotice = XLuaUiManager.Register(XLuaUi, "UiLoginNotice")

function XUiLoginNotice:OnAwake()
    self:AutoAddListener()
    self._IsClose = false
end

function XUiLoginNotice:OnStart(loginNotice, showToggleTodayOnce)
    if not loginNotice or not loginNotice.HtmlUrl then
        return
    end
    self.WebHtmlView = XUiPanelWebHtmlView.New(self.PanelWebView, self)
    self.WebHtmlView:SetLoadingActive(true)
    if loginNotice.isFullUrl then
        self:SendWebRequestForCustom(loginNotice)
    else
        self:SendWebRequestForLogin(loginNotice)
    end

    self.TxtTitle.text = loginNotice.Title
    if self.TogClose then
        if showToggleTodayOnce then
            self.TogClose.isOn = XDataCenter.NoticeManager.CheckHasOpenLoginNotice()
            self.TogClose.gameObject:SetActiveEx(true)
        else
            self.TogClose.gameObject:SetActiveEx(false)
        end
    end
end

function XUiLoginNotice:SendWebRequestForLogin(loginNotice)
    local request = CS.XUriPrefixRequest.Get(loginNotice.HtmlUrl)

    CS.XRecord.Record("24030", "LoginNoticeRequestStart")
    CS.XTool.WaitCoroutine(request:SendWebRequest(), function()
        if request.isNetworkError or request.isHttpError then
            local msgTab = {}
            msgTab.error = request.error
            CS.XRecord.Record(msgTab, "24001", "LoginNoticeError")
            return
        elseif not request.downloadHandler then
            local msgTab = {}
            msgTab.error = "request.downloadHandler is nil"
            CS.XRecord.Record(msgTab, "24002", "LoginNoticeError")
            return
        end

        self:LoadByHtml(request, loginNotice)
    end)
end

function XUiLoginNotice:SendWebRequestForCustom(loginNotice)
    local request = CS.XUriPrefixRequest.Get(loginNotice.HtmlUrl)

    CS.XTool.WaitCoroutine(request:SendWebRequest(loginNotice.HtmlUrl), function()
        self:LoadByHtml(request, loginNotice)
    end)
end

function XUiLoginNotice:LoadByHtml(request, loginNotice)
    if self._IsClose then
        return
    end
    if request.isNetworkError or request.isHttpError or not request.downloadHandler then
        return
    end
    local content = request.downloadHandler.text
    if string.IsNilOrEmpty(content) then
        return
    end
    request:Dispose()
    
    self.WebHtmlView:ShowHtml(content)
end

function XUiLoginNotice:OnDestroy()
    self._IsClose = true
end

function XUiLoginNotice:OnGetEvents()
    return { XEventId.EVENT_UIDIALOG_VIEW_ENABLE }
end

function XUiLoginNotice:OnNotify(evt)
    if evt == XEventId.EVENT_UIDIALOG_VIEW_ENABLE then
        self:Close()
    end
end

function XUiLoginNotice:AutoAddListener()
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
    if self.TogClose then
        self:RegisterClickEvent(self.TogClose, self.OnTogCloseClick)
    end
end

-- auto

function XUiLoginNotice:OnBtnCloseClick()
    self:Close()
end

function XUiLoginNotice:OnTogCloseClick()
    if self.TogClose then
        XDataCenter.NoticeManager.SaveOpenLoginNoticeValue(self.TogClose.isOn)
    end
end

return XUiLoginNotice
