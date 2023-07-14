local XUiWindowsInlay = XLuaUiManager.Register(XLuaUi, "UiWindowsInlay")
local XHtmlHandler = require("XUi/XUiGameNotice/XHtmlHandler")
local Object = CS.UnityEngine.Object
local textUrl = [[file://]] .. CS.UnityEngine.Application.persistentDataPath .. "/test/url.txt" ---方便测试
function XUiWindowsInlay:OnStart()
    self.ActivityList = {}
    self.ActivityBtn = {}
    self:SetButtonCallBack()
    self:InitButton()
end

function XUiWindowsInlay:OnEnable()
    self.PanelBottomRight:SelectIndex(self.CurIndex)
end

function XUiWindowsInlay:OnDisable()
    if not XTool.UObjIsNil(self.WebViewPanel) then
        CS.UnityEngine.Object.DestroyImmediate(self.WebViewPanel.gameObject)
        self.WebViewPanel = nil
    end
end

function XUiWindowsInlay:SetButtonCallBack()
    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end
    self.BtnMainUi.CallBack = function()
        self:OnBtnMainUiClick()
    end
end

function XUiWindowsInlay:InitButton()
    self.ActivityList = XDataCenter.MarketingActivityManager.GetWindowsInlayInTimeActivityList()
    self.BtnTabActivity.gameObject:SetActive(false)
    self.CurIndex = 1
    for _, activity in pairs(self.ActivityList) do
        local btn = Object.Instantiate(self.BtnTabActivity)
        btn.gameObject:SetActive(true)
        btn.transform:SetParent(self.PanelBottomRight.transform, false)
        local btncs = btn:GetComponent("XUiButton")
        local name = activity.Title
        btncs:SetName(name or "Null")
        table.insert(self.ActivityBtn, btncs)
    end
    self.PanelBottomRight:Init(self.ActivityBtn, function(index) self:SelectActivity(index) end)
end

function XUiWindowsInlay:SelectActivity(index)
    local activityInfo = self.ActivityList[index]
    local url = activityInfo and activityInfo.Url or ""
    local type = activityInfo and activityInfo.Type or 0

    if type == XMarketingActivityConfigs.WebType.Normal then
        self:ShowHtml(url)
    elseif type == XMarketingActivityConfigs.WebType.Vote then
        XDataCenter.MarketingActivityManager.RequestVoteToken(type, function ()
                XScheduleManager.ScheduleOnce(function()
                        local token = XDataCenter.MarketingActivityManager.GetWindowsInlayTokenByType(type)
                        self:ShowHtml(url, token)
                    end, 1)
            end)
    end

end

function XUiWindowsInlay:OnBtnBackClick()
    self:Close()
end

function XUiWindowsInlay:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiWindowsInlay:ShowHtml(webUrl, token)
    if not XTool.UObjIsNil(self.WebViewPanel) then
        CS.UnityEngine.Object.DestroyImmediate(self.WebViewPanel.gameObject)
        self.WebViewPanel = nil
    end

    local urlStr = token and string.format("%s?token=%s", webUrl, token) or webUrl
    self.WebViewPanel = CS.UnityEngine.Object.Instantiate(self.PanelWebView, self.PanelWebView.parent)
    local webView = CS.XWebView.GetWebView(self.WebViewPanel.gameObject, function() XLog.Error("XUiWindowsInlay:ShowHtml函数错误, 原因网络加载异常", url) end)
    webView:LoadURL(string.gsub(urlStr, " ", XHtmlHandler.FilterSpecialSymbol("%20")))

end