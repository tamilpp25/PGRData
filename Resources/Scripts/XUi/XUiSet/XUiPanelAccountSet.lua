XUiPanelAccountSet = XClass(nil, "XUiPanelAccountSet")
local Json = require("XCommon/Json")

function XUiPanelAccountSet:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.MyColor = CS.UnityEngine.Color()
    self:AddListener()
    self:InitPanelData()
end

function XUiPanelAccountSet:AddListener()
    XUiHelper.RegisterClickEvent(self, self.FacebookBind, self.OnBindFacebook)
    XUiHelper.RegisterClickEvent(self, self.GoogleBind, self.OnBindGoogle)
    XUiHelper.RegisterClickEvent(self, self.TwitterBind, self.OnBindTwitter)
    XUiHelper.RegisterClickEvent(self, self.AppleBind, self.OnBindApple)
    XUiHelper.RegisterClickEvent(self, self.BackLogin, self.OnLogout)

    XEventManager.AddEventListener(XEventId.EVENT_HGSDK_GET_BIND, self.OnGetBindState, self)
    XEventManager.AddEventListener(XEventId.EVENT_HGSDK_BIND_RESULT, self.OnBindResult, self)

    self.TwitterBind.transform.parent.gameObject:SetActiveEx(false)
    self.BtnAccountCancellation.CallBack = function()
        XHgSdkManager.AccountCancellation()
    end
end

function XUiPanelAccountSet:OnBindFacebook()
    self.CurBindType = XHgSdkManager.UserType.FaceBook
    XHgSdkManager.StartBind(XHgSdkManager.UserType.FaceBook)
end

function XUiPanelAccountSet:OnBindGoogle()
    self.CurBindType = XHgSdkManager.UserType.Google
    XHgSdkManager.StartBind(XHgSdkManager.UserType.Google)
end

function XUiPanelAccountSet:OnLogout()
    XUserManager.ShowLogout()
end

function XUiPanelAccountSet:OnLogoutInfo()
    XHgSdkManager.AccountCancellation()
end

function XUiPanelAccountSet:OnBindTwitter()
    self.CurBindType = XHgSdkManager.UserType.Twitter
    XHgSdkManager.StartBind(XHgSdkManager.UserType.Twitter)
end

function XUiPanelAccountSet:OnBindApple()
    self.CurBindType = XHgSdkManager.UserType.Apple
    XHgSdkManager.StartBind(XHgSdkManager.UserType.Apple)
end

function XUiPanelAccountSet:OnGetBindState(stateJson)
    self.BindState = Json.decode(stateJson)
    self:SetPanelData()
end

--由HgSDK绑定的结果回调
function XUiPanelAccountSet:OnBindResult(success, msg)
    msg = msg or ""
    if success then
        XUiManager.TipSuccess("Account binding successful")
        if self.CurBindType == nil then
            CS.UnityEngine.Debug.LogError("当前绑定类型为空")
            return
        elseif self.CurBindType == XHgSdkManager.UserType.FaceBook then
            self.BindState.fbBind = 1;
            XUserManager.SetUserType(self.CurBindType);
            XHgSdkManager.OnBindTaskFinished();
        elseif self.CurBindType == XHgSdkManager.UserType.Google then
            self.BindState.googleBind = 1;
            XUserManager.SetUserType(self.CurBindType);
            XHgSdkManager.OnBindTaskFinished();
        elseif self.CurBindType == XHgSdkManager.UserType.Twitter then
            self.BindState.twitterBind = 1
            XUserManager.SetUserType(self.CurBindType)
            XHgSdkManager.OnBindTaskFinished()
        elseif self.CurBindType == XHgSdkManager.UserType.Line then
            self.BindState.lineBind = 1
            XUserManager.SetUserType(self.CurBindType)
            XHgSdkManager.OnBindTaskFinished()
        elseif self.CurBindType == XHgSdkManager.UserType.Apple then
            self.BindState.appleBind = 1
            XUserManager.SetUserType(self.CurBindType)
            XHgSdkManager.OnBindTaskFinished()
        elseif self.CurBindType == XHgSdkManager.UserType.Suid then
            XUserManager.SetPasswordStatus(1)
        end

        self:SetPanelData()
        self.CurBindType = nil
    else
        XUiManager.TipSuccess("Account binding failed:" .. msg)
    end
end

function XUiPanelAccountSet:InitPanelData()
    --获取绑定的结果
    self.BindState = nil
    self.CurBindType = nil
    self.AppleGroup.gameObject:SetActiveEx(CS.UnityEngine.Application.platform == CS.UnityEngine.RuntimePlatform.IPhonePlayer);
    self.FacebookBind.gameObject:SetActiveEx(false);
    self.GoogleBind.gameObject:SetActive(false);
    self.TwitterBind.gameObject:SetActiveEx(false)
    self.AppleBind.gameObject:SetActiveEx(false)
    self.GoogleBinded.gameObject:SetActiveEx(false)
    self.FacebookBinded.gameObject:SetActiveEx(false)
    self.TwitterBinded.gameObject:SetActiveEx(false)
    self.AppleBinded.gameObject:SetActiveEx(false)
    self.AccountCancellationItem.gameObject:SetActiveEx(CS.XRemoteConfig.AccountCancellationEnable);--暂时只是IOS

    if self.BindState == nil then
        XHgSdkManager.GetBindState()
    else
        self:SetPanelData()
    end
end

function XUiPanelAccountSet:SetPanelData()
    --{"code":0,"msg":"成功","fbBind":0,"googleBind":0,"gcBind":0,"weChatBind":0,"twitterBind":0,"appleBind":0,"lineBind":0}
    self.FacebookBind.gameObject:SetActiveEx(self.BindState.fbBind == 0);
    self.GoogleBind.gameObject:SetActive(self.BindState.googleBind == 0);
    self.TwitterBind.gameObject:SetActiveEx(self.BindState.twitterBind == 0)
    self.AppleBind.gameObject:SetActiveEx(self.BindState.appleBind == 0)

    self.FacebookBinded.gameObject:SetActiveEx(self.BindState.fbBind == 1)
    self.GoogleBinded.gameObject:SetActiveEx(self.BindState.googleBind == 1)
    self.TwitterBinded.gameObject:SetActiveEx(self.BindState.twitterBind == 1)
    self.AppleBinded.gameObject:SetActiveEx(self.BindState.appleBind == 1)
end

function XUiPanelAccountSet:ShowPanel()
    self.IsShow = true
    self.GameObject:SetActive(true)
    if self.BindState == nil then
        XHgSdkManager.GetBindState()
    else
        self:SetPanelData()
    end
end

function XUiPanelAccountSet:HidePanel()
    self.IsShow = false
    self.GameObject:SetActive(false)
end

function XUiPanelAccountSet:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_HGSDK_GET_BIND, self.OnGetBindState, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_HGSDK_BIND_RESULT, self.OnBindResult, self)
end

function XUiPanelAccountSet:CheckDataIsChange()
    return false
end