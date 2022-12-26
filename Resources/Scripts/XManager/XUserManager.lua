XUserManager = XUserManager or {}

local Application = CS.UnityEngine.Application
local Platform = Application.platform
local RuntimePlatform = CS.UnityEngine.RuntimePlatform

XUserManager.CHANNEL = {
    HARU = 1,
    HERO = 2,
    Android = 3,
    IOS = 4,
    ONESTORE = 5,
    HUAWEI = 6,
    OPPO = 7,
    KuroPC = 15,
}

XUserManager.PLATFORM = {
    Win = 0,
    Android = 1,
    IOS = 2
}

XUserManager.UserId = nil
XUserManager.UserName = nil
XUserManager.Token = nil
XUserManager.ReconnectedToken = nil
XUserManager.Channel = nil
XUserManager.Platform = nil

local UserType = XHgSdkManager.UserType

local InitPlatform = function()
    if Platform == RuntimePlatform.Android then
        XUserManager.Platform = XUserManager.PLATFORM.Android
        XHgSdkManager.SetCallBackUrl(CS.XRemoteConfig.AndroidPayCallbackUrl)
    elseif Platform == RuntimePlatform.IPhonePlayer then
        XUserManager.Platform = XUserManager.PLATFORM.IOS
        XHgSdkManager.SetCallBackUrl(CS.XRemoteConfig.IosPayCallbackUrl)
    else
        XUserManager.Platform = XUserManager.PLATFORM.Win
    end
end

function XUserManager.Init()
    XUserManager.Channel = CS.XHgSdkAgent.LoginType or XUserManager.CHANNEL.HARU
    XUserManager.UserId = XLoginManager.GetUserId()
    XUserManager.UserType = XLoginManager.GetUserType() or UserType.Vistor
    XUserManager.PasswordStatus = tonumber(XLoginManager.GetPasswordStatus() or "0") or 0
    if XUserManager.Channel ~= XUserManager.CHANNEL.Android and  XUserManager.Channel ~= XUserManager.CHANNEL.IOS then
        XUserManager.Token = XLoginManager.GetToken()
        XUserManager.SetPasswordStatus(0)
    end
    InitPlatform()
end

function XUserManager.IsNeedLogin()
    if (XUserManager.Channel == XUserManager.CHANNEL.Android) or (XUserManager.Channel == XUserManager.CHANNEL.IOS) or XUserManager.Channel == XUserManager.CHANNEL.KuroPC then
        return XHgSdkManager.IsNeedLogin()
    else
        return XHaruUserManager.IsNeedLogin()
    end
end

function XUserManager.HasLoginError()
    if XUserManager.Channel == XUserManager.CHANNEL.HERO then
        return XHeroSdkManager.HasLoginError()
    else
        return false
    end
end

function XUserManager.ShowLogin()
    if XUserManager.Channel == XUserManager.CHANNEL.Android or XUserManager.Channel == XUserManager.CHANNEL.IOS or XUserManager.Channel == XUserManager.CHANNEL.KuroPC then
        XHgSdkManager.Login(XHgSdkManager.UserType.Quickly) -- 默认快速登录逻辑
    else
        XHaruUserManager.Login()
    end
end

function XUserManager.ShowLogout()
    if XUserManager.Channel == XUserManager.CHANNEL.Android or XUserManager.Channel == XUserManager.CHANNEL.IOS then
        XHgSdkManager.BackToLogin()
    elseif XUserManager.Channel == XUserManager.CHANNEL.KuroPC then
        XHgSdkManager.Logout()
    else
        XHaruUserManager.Logout()
    end
end

function XUserManager.Logout(cb)
    if XUserManager.Channel == XUserManager.CHANNEL.Android or XUserManager.Channel == XUserManager.CHANNEL.IOS or XUserManager.Channel == XUserManager.CHANNEL.KuroPC then
        XHgSdkManager.Logout(cb)
    else
        XHaruUserManager.Logout(cb)
    end
end

function XUserManager.ClearLoginData()
    if XUserManager.Channel == XUserManager.CHANNEL.Android or XUserManager.Channel == XUserManager.CHANNEL.IOS or XUserManager.Channel == XUserManager.CHANNEL.KuroPC then
        XHgSdkManager.Logout()
    else
        XUserManager.SignOut()
    end
end

function XUserManager.SetUserId(userId)
    XUserManager.UserId = userId
    CS.XHeroBdcAgent.UserId = "HeroEn#" .. (userId or "")
    XLoginManager.SetUserId(userId)
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_USERID_CHANGE, userId)
end

function XUserManager.CleanUserId()
    XUserManager.UserId = nil
    XLoginManager.CleanUserId()
    XEventManager.DispatchEvent(XEventId.EVENT_USERID_CHANGE, nil)
end

function XUserManager.SetUserType(userType)
    XUserManager.UserType = userType
    XLoginManager.SetUserType(userType)
end

function XUserManager.CleanUserType()
    XUserManager.UserType = nil
    XLoginManager.CleanUserType()
end

function XUserManager.SetPasswordStatus(status)
    XUserManager.PasswordStatus = status
    XLoginManager.SetPasswordStatus(status)
end

function XUserManager.SetUserName(userName)
    XUserManager.UserName = userName
    if XUserManager.Channel ~= XUserManager.CHANNEL.HERO then
        CS.UnityEngine.PlayerPrefs.SetString(XPrefs.UserName, XUserManager.UserName)
        CS.UnityEngine.PlayerPrefs.Save()
    end
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_USERNAME_CHANGE, userName)
end

function XUserManager.SetToken(token)
    XUserManager.Token = token
    if XUserManager.Channel ~= XUserManager.CHANNEL.Android and XUserManager.Channel ~= XUserManager.CHANNEL.IOS and XUserManager.Channel ~= XUserManager.CHANNEL.KuroPC then
        XLoginManager.SetToken(token)
    end
end

function XUserManager.CleanToken()
    XUserManager.Token = nil
    XLoginManager.CleanToken()
end

local DoRunLogin = function()
    if CS.XFight.Instance ~= nil then
        CS.XFight.ClearFight()
    end
    if XDataCenter.MovieManager then
        XDataCenter.MovieManager.StopMovie()
    end
    CS.Movie.XMovieManager.Instance:Clear()
    CsXUiManager.Instance:Clear()
    XHomeSceneManager.LeaveScene()
    CsXUiManager.Instance:Open("UiLogin")
end

function XUserManager.SignOut()
    XLoginManager.Disconnect()

    if XUserManager.Channel ~= XUserManager.CHANNEL.Android and XUserManager.Channel ~= XUserManager.CHANNEL.IOS then
        XUserManager.SetUserId(nil)
        XUserManager.SetUserName(nil)
        XUserManager.SetToken(nil)
        XUserManager.SetPasswordStatus(0)
    end

    XEventManager.DispatchEvent(XEventId.EVENT_USER_LOGOUT)
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_USER_LOGOUT)
    XDataCenter.Init()
    DoRunLogin()
end

function XUserManager.OnSwitchAccountSuccess(uid, token, userType)
    XLoginManager.Disconnect()

    XUserManager.SetUserId(uid)
    XUserManager.SetUserType(userType)
    XUserManager.SetToken(token)

    XEventManager.DispatchEvent(XEventId.EVENT_USER_LOGOUT)
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_USER_LOGOUT)

    XDataCenter.Init()
    DoRunLogin()
end

XRpc.LoginResponse = function(response)
    if response.Token then
        XUserManager.ReconnectedToken = response.Token
        --BDC
        CS.XHeroBdcAgent.UserId = "HeroEn#" .. XUserManager.UserId
        if XUserManager.Channel ~= XUserManager.CHANNEL.Android and XUserManager.Channel ~= XUserManager.CHANNEL.IOS then
            XLoginManager.SetUserId(XUserManager.UserId)
            XLoginManager.SetToken(XUserManager.Token)
            XLoginManager.SetUserType(XUserManager.UserType)
            XLoginManager.SetPasswordStatus(XUserManager.PasswordStatus)
        end
    end
end