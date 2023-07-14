local XUiLoginNotice = XLuaUiManager.Register(XLuaUi, "UiLoginNotice")

function XUiLoginNotice:OnAwake()
    self:InitAutoScript()
end


function XUiLoginNotice:OnStart(loginNotice)
    if XLuaUiManager.IsUiShow("UiLoginAgreement") then
        XLuaUiManager.Close("UiLoginAgreement")
    end

    if not loginNotice or not loginNotice.HtmlUrl then
        return
    end

    if loginNotice.isFullUrl then
        self:SendWebRequestForCustom(loginNotice)
    else
        self:SendWebRequestForLogin(loginNotice)
    end

    self.TxtTitle.text = loginNotice.Title
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
    if request.isNetworkError or request.isHttpError or not request.downloadHandler then
        return
    end

    if CS.UnityEngine.Application.platform == CS.UnityEngine.RuntimePlatform.WindowsEditor or 
    CS.UnityEngine.Application.platform == CS.UnityEngine.RuntimePlatform.WindowsPlayer then
        --PC上，直接加载网页
        self.PCPanelWebView.gameObject:SetActiveEx(true);
        CS.XWebView.PCLoadHTML(self.PCPanelWebView.gameObject, request.downloadHandler.text)
    else
         -- 手机上暂时使用旧方法，将HTML文本显示上去
        --此WEB VIEW仅会在手机平台上显示
        self.PCPanelWebView.gameObject:SetActiveEx(false)
        local html = request.downloadHandler.text
        CS.XWebView.LoadByHtml(self.PanelWebView.gameObject, html)
    end

    -- --此WEB VIEW仅会在手机平台上显示
    -- local html = request.downloadHandler.text
    -- CS.XWebView.LoadByHtml(self.PanelWebView.gameObject, html)
end


function XUiLoginNotice:OnEnable()
end


function XUiLoginNotice:OnDisable()
end


function XUiLoginNotice:OnDestroy()
end


function XUiLoginNotice:OnGetEvents()
    return {XEventId.EVENT_UIDIALOG_VIEW_ENABLE}
end


function XUiLoginNotice:OnNotify(evt)
    if evt == XEventId.EVENT_UIDIALOG_VIEW_ENABLE then
        self:Close()
    end
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiLoginNotice:InitAutoScript()
    self:AutoInitUi()
    self:AutoAddListener()
end

function XUiLoginNotice:AutoInitUi()
    self.PanelWebView = self.Transform:Find("Animator/SafeAreaContentPane/PanelWebView")
    self.PCPanelWebView = self.Transform:Find("Animator/SafeAreaContentPane/PCPanelWebView")
    self.TxtTitle = self.Transform:Find("Animator/SafeAreaContentPane/TxtTitle"):GetComponent("Text")
    self.BtnClose = self.Transform:Find("Animator/SafeAreaContentPane/BtnClose"):GetComponent("Button")
    self.TxtClose = self.Transform:Find("Animator/SafeAreaContentPane/BtnClose/TxtClose"):GetComponent("Text")
end

function XUiLoginNotice:AutoAddListener()
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
end
-- auto

function XUiLoginNotice:OnBtnCloseClick()
    self:Close()
    XEventManager.DispatchEvent(XEventId.EVENT_WHEN_CLOSE_LOGIN_NOTICE)
end