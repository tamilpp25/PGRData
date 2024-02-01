XHeroSdkManager = XHeroSdkManager or {}

local Json = require("XCommon/Json")

local Application = CS.UnityEngine.Application
local Platform = Application.platform
local RuntimePlatform = CS.UnityEngine.RuntimePlatform

local IsSdkLogined = false
local LogoutSccess = 0
local LogoutFailed = 1
local LogoutCb = nil
local LastTimeOfCallSdkLoginUi = 0
local CallLoginUiCountDown = 2
local HeroRoleInfo = CS.XHeroRoleInfo
local HeroOrderInfo = CS.XHeroOrderInfo
local PayCallbacks = {}     -- android 充值回调
local IOSPayCallback = nil  -- iOS 充值回调
local HasSdkLoginError = false -- sdk登陆存在错误
--local CallbackUrl = "http://haru.free.idcfengye.com/api/XPay/HeroPayResult"
local CallbackUrl = CS.XRemoteConfig.PayCallbackUrl
local XRecordUserInfo = CS.XRecord.XRecordUserInfo

local IsNeedShowReddot = false

local CleanPayCallbacks = function()
    PayCallbacks = {}
    IOSPayCallback = nil
end

function XHeroSdkManager.IsNeedLogin()
    return not (CS.XHeroSdkAgent.IsLogined() and IsSdkLogined)
end

function XHeroSdkManager.HasLoginError()
    return HasSdkLoginError
end

function XHeroSdkManager.Login()
    if not XHeroSdkManager.IsNeedLogin() then
        CS.XRecord.Record("24035", "HeroSdkRepetitionLogin")
        return
    end

    local curTime = CS.UnityEngine.Time.realtimeSinceStartup
    if curTime - LastTimeOfCallSdkLoginUi < CallLoginUiCountDown then
        CS.XRecord.Record("24036", "HeroSdkShortTimeLogin")
        return
    end
    LastTimeOfCallSdkLoginUi = curTime
    
    HasSdkLoginError = false
    CS.XRecord.Record("24023", "HeroSdkLogin")
    CS.XHeroSdkAgent.Login()
end

function XHeroSdkManager.Logout(cb)
    if XHeroSdkManager.IsNeedLogin() then
        if cb then
            cb(LogoutFailed)
        end
        return
    end

    LogoutCb = cb
    CS.XRecord.Record("24029", "HeroSdkLogout")
    CS.XHeroSdkAgent.Logout()

    if Platform == RuntimePlatform.IPhonePlayer then
        -- iOS 无回调，直接调用退出
        XHeroSdkManager.OnLogoutSuccess()
    end
end

function XHeroSdkManager.OnLoginSuccess(uid, username, token, loginChannel)
    if IsSdkLogined and XUserManager.UserId ~= uid then
        XLog.Error("重复的登陆成功回调 user_id1:" .. tostring(XUserManager.UserId) .. ", user_id2:" .. tostring(uid))
        HasSdkLoginError = true
    end
    IsSdkLogined = true
    LastTimeOfCallSdkLoginUi = 0

    XLog.Debug("uid:" .. tostring(uid) .. ", username:" .. tostring(username) .. ", token:" .. tostring(token))
    XUserManager.SetUserId(uid)
    XUserManager.SetUserName(username)
    XUserManager.SetToken(token)
    XUserManager.SetLoginChannel(loginChannel)

    local info = XRecordUserInfo()
    info.UserId = XUserManager.GetUniqueUserId()
    info.UserName = username
    CS.XRecord.Login(info)
    CS.XRecord.Record("24024", "HeroSdkLoginSuccess")

    CleanPayCallbacks()
end

function XHeroSdkManager.OnLoginFailed(msg)
    XLog.Error("Hero sdk login failed. " .. msg)
    IsSdkLogined = false
    CS.XRecord.Record("24032", "HeroSdkLoginFailed")
    local errorTxt = CS.XTextManager.GetText("HeroSdkLoginFailed")
    -- KuroSDK提供的，如果登录失败返回这个，则是SDK未初始化完，换个提醒
    if string.match(msg, "failed for init not accomplished") then 
        errorTxt = CS.XTextManager.GetText("HeroSdkNotInit")
    end
    LastTimeOfCallSdkLoginUi = 0
    XUiManager.SystemDialogTip(CS.XTextManager.GetText("TipTitle"), errorTxt, XUiManager.DialogType.OnlySure, nil, function()
        XHeroSdkManager.Login()
    end)
end

function XHeroSdkManager.OnLoginCancel()
    IsSdkLogined = false
    LastTimeOfCallSdkLoginUi = 0
    -- CS.XRecord.Record("24032", "HeroSdkLoginFailed")
end

function XHeroSdkManager.OnSwitchAccountSuccess(uid, username, token)
    -- 先设置UserId
    XUserManager.OnSwitchAccountSuccess(uid, username, token)

    -- 再进行埋点
    local info = XRecordUserInfo()
    info.UserId = XUserManager.GetUniqueUserId()
    info.UserName = username
    CS.XRecord.Login(info)
    CS.XRecord.Record("24025", "HeroSdkSwitchAccountSuccess")

    CleanPayCallbacks()
end

function XHeroSdkManager.OnSwitchAccountFailed(msg)
    CS.XRecord.Record("24026", "HeroSdkSwitchAccountFailed")
    XUiManager.SystemDialogTip(CS.XTextManager.GetText("TipTitle"), msg, XUiManager.DialogType.OnlySure, nil, nil)
end

function XHeroSdkManager.OnSwitchAccountCancel()
    --TODO
end

function XHeroSdkManager.OnLogoutSuccess()
    IsSdkLogined = false
    CS.XRecord.Record("24027", "HeroSdkLogoutSuccess")
    CS.XRecord.Logout()
    CleanPayCallbacks()
    XUserManager.SignOut()

    if LogoutCb then
        LogoutCb(LogoutSccess)
        LogoutCb = nil
    end
end

function XHeroSdkManager.OnLogoutFailed(msg)
    IsSdkLogined = true
    CS.XRecord.Record("24028", "HeroSdkLogoutFailed")
    XUiManager.SystemDialogTip(CS.XTextManager.GetText("TipTitle"), msg, XUiManager.DialogType.OnlySure, nil, nil)

    if LogoutCb then
        LogoutCb(LogoutFailed)
        LogoutCb = nil
    end
end

function XHeroSdkManager.OnSdkKickOff(msg)
    XLog.Debug("XHeroSdkManager.OnSdkKickOff()  msg = " .. msg)
    XDataCenter.AntiAddictionManager.Kick(msg)
end

local GetRoleInfo = function()
    local roleInfo = HeroRoleInfo()
    roleInfo.Id = XPlayer.Id
    if XUserManager.IsKuroSdk() then 
        -- 库洛母包需要有正确的区服ID，下面那个else获取的是服务器列表索引值，其实是错的
        roleInfo.ServerId = CS.XHeroBdcAgent.ServerId
    else 
        roleInfo.ServerId = XServerManager.Id
    end
    roleInfo.ServerName = XServerManager.ServerName
    roleInfo.Name = XPlayer.Name
    roleInfo.Level = XPlayer.Level
    roleInfo.CreateTime = XPlayer.CreateTime
    roleInfo.PaidGem = XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.PaidGem)
    roleInfo.Coin = XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.Coin)
    roleInfo.SumPay = 0
    roleInfo.VipLevel = 0
    roleInfo.PartyName = nil

    return roleInfo
end

function XHeroSdkManager.EnterGame()
    if not XUserManager.IsUseSdk() then
        return
    end
    CS.XHeroSdkAgent.EnterGame(GetRoleInfo())
end

function XHeroSdkManager.CreateNewRole()
    if not XUserManager.IsUseSdk() then
        return
    end
    CS.XHeroSdkAgent.CreateNewRole(GetRoleInfo())
end

function XHeroSdkManager.RoleLevelUp()
    if not XUserManager.IsUseSdk() then
        return
    end
    CS.XHeroSdkAgent.RoleLevelUp(GetRoleInfo())
end

local GetOrderInfo = function(cpOrderId, goodsId, extraParams,productKey)
    local orderInfo = HeroOrderInfo()
    orderInfo.CpOrderId = cpOrderId
    orderInfo.GoodsId = goodsId

    if extraParams and _G.next(extraParams) then
        orderInfo.ExtraParams = Json.encode(extraParams)
    end
    local template = XPayConfigs.GetPayTemplate(productKey)

    if XUserManager.IsKuroSdk() and template then
        orderInfo.Price = template.Amount
        orderInfo.GoodsName = template.Name
        orderInfo.GoodsDesc = template.Desc
    end
    -- if productInfo.GoodsName and #productInfo.GoodsName > 0 then
    --     orderInfo.GoodsName = productInfo.GoodsName
    -- end
    -- if productInfo.GoodsDesc and #productInfo.GoodsDesc > 0 then
    --     orderInfo.GoodsDesc = productInfo.GoodsDesc
    -- end
    -- if productInfo.Amount and productInfo.Amount > 0 then
    --     orderInfo.Amount = productInfo.Amount
    -- end
    -- if productInfo.Price and productInfo.Price > 0 then
    --     orderInfo.Price = productInfo.Price
    -- end
    -- if productInfo.Count and productInfo.Count > 0 then
    --     orderInfo.Count = productInfo.Count
    -- end
    if CallbackUrl then
        orderInfo.CallbackUrl = CallbackUrl
    end

    return orderInfo
end

function XHeroSdkManager.Pay(productKey, cpOrderId, goodsId, cb)
    -- local extraParams = {
    --     PlayerId = XPlayer.Id,
    --     ProductKey = productKey,
    --     CpOrderId = cpOrderId,
    --     ProductId = productInfo.ProductId
    -- }
    if Platform == RuntimePlatform.Android then
        PayCallbacks[cpOrderId] = {
            cb = cb,
            info = {
                ProductKey = productKey,
                CpOrderId = cpOrderId,
                GoodsId = goodsId,
                PlayerId = XPlayer.Id
            }
        }
    end

    local order = GetOrderInfo(cpOrderId, goodsId,nil,productKey)
    CS.XHeroSdkAgent.Pay(order, GetRoleInfo())
    XDataCenter.AntiAddictionManager.BeginPayAction()
end

function XHeroSdkManager.OnPayAndSuccess(sdkOrderId, cpOrderId)
    local cbInfo = PayCallbacks[cpOrderId]
    if cbInfo and cbInfo.cb then
        cbInfo.info.sdkOrderId = sdkOrderId
        cbInfo.cb(nil, cbInfo.info)
    end

    PayCallbacks[cpOrderId] = nil
    XDataCenter.AntiAddictionManager.EndPayAction()
end

function XHeroSdkManager.OnPayAndFailed(cpOrderId, msg)
    local cbInfo = PayCallbacks[cpOrderId]
    if cbInfo and cbInfo.cb then
        cbInfo.cb(msg, cbInfo.info)
    end

    PayCallbacks[cpOrderId] = nil
    XDataCenter.AntiAddictionManager.EndPayAction()
end

function XHeroSdkManager.OnPayAndCancel(cpOrderId)
    PayCallbacks[cpOrderId] = nil
    XDataCenter.AntiAddictionManager.EndPayAction()
end

function XHeroSdkManager.OnPayIOSSuccess(orderId)
    if IOSPayCallback then
        IOSPayCallback(nil, orderId)
    end
    XDataCenter.AntiAddictionManager.EndPayAction()
end

function XHeroSdkManager.OnPayIOSFailed(msg)
    if IOSPayCallback then
        IOSPayCallback(msg)
    end
    XDataCenter.AntiAddictionManager.EndPayAction()
end

function XHeroSdkManager.RegisterIOSCallback(cb)
    IOSPayCallback = cb
end

-- 客服接口
function XHeroSdkManager.Feedback(from, isLogin)
    -- 加上返回是为了兼容是否有接入SDK
    if CS.XHeroSdkAgent.Feedback then 
        CS.XHeroSdkAgent.Feedback(from, isLogin, GetRoleInfo())
        return true
    end
    return false
end

-- 客服回调，用于触发红点刷新
function XHeroSdkManager.FeedbackCallback()
    IsNeedShowReddot = true
    XEventManager.DispatchEvent(XEventId.EVENT_FEEDBACK_REFRESH)
end

-- 检测客服红点
function XHeroSdkManager.CheckShowReddot()
    return IsNeedShowReddot
end

-- 清理客服红点
function XHeroSdkManager.ClearReddot()
    IsNeedShowReddot = false
end

-- 分享是否开放
function XHeroSdkManager.SharePlatformIsEnable(platform)
    return CS.XHeroSdkAgent.SharePlatformIsEnable(platform)
end

-- 分享
function XHeroSdkManager.Share(platform, path, callback, title, text, topics)
    CS.XHeroSdkAgent.Share(platform, path, callback, title, text, topics)
end