XHgSdkManager = XHgSdkManager or {}

local Json = require("XCommon/Json")

local Application = CS.UnityEngine.Application
local Platform = Application.platform
local RuntimePlatform = CS.UnityEngine.RuntimePlatform

local IsSdkLogined = false

local LastTimeOfCallSdkLoginUi = 0
local CallLoginUiCountDown = 2

local HgOrderInfo = CS.XHgOrderInfo

local PayCallbacks = {}     -- android 充值回调
local IOSPayCallback = nil  -- iOS 充值回调

local CallbackUrl = CS.XRemoteConfig.PayCallbackUrl

local XRecordUserInfo = CS.XRecord.XRecordUserInfo

local CleanPayCallbacks = function()
    PayCallbacks = {}
    IOSPayCallback = nil
end

XHgSdkManager.UserType = {
    Quickly = 2333, -- 快速登录（没有默认游客，有账号就上次登录）
    Vistor = 0,
    FaceBook = 1,
    Google = 2,
    GameCenter = 3,
    WeChat = 4,
    Twitter = 5,
    Line = 6,
    Apple = 7,
    Line = 8,
    Suid = 9,
    Huawei = 10,
    Oppo = 11,
}

--检测SDK是否已经登录
local checkNeedLogin = function()
    if not XHgSdkManager.IsNeedLogin() then
        XLog.Debug("SDK不需要登录")
        CS.XRecord.Record("24035", "HeroSdkRepetitionLogin")
        return false
    end
    return true
end

--检测登录间隔
local checkLoginTimeTooFast = function()
    local curTime = CS.UnityEngine.Time.realtimeSinceStartup
    if curTime - LastTimeOfCallSdkLoginUi < CallLoginUiCountDown then
        XLog.Debug("请求SDK登录时间过短")
        CS.XRecord.Record("24036", "HeroSdkShortTimeLogin")
        return false
    end
    LastTimeOfCallSdkLoginUi = curTime
    return true
end


function XHgSdkManager.IsNeedLogin()
    return not IsSdkLogined
end

function XHgSdkManager.SetCallBackUrl(url)
    CallbackUrl = url
end

function XHgSdkManager.LoginQuickly()
    XLog.Debug("SDK登录类型:快速登录");
    CS.XHgSdkAgent.LoginQuickly();
end

function XHgSdkManager.LoginVisitor()
    XLog.Debug("SDK登录类型:游客登录");
    CS.XHgSdkAgent.SwitchAccount(XHgSdkManager.UserType.Vistor);
end

function XHgSdkManager.LoginGoogle()
    XLog.Debug("SDK登录类型:Google登录");
    CS.XHgSdkAgent.SwitchAccount(XHgSdkManager.UserType.Google);
end

function XHgSdkManager.LoginFacebook()
    XLog.Debug("SDK登录类型:Facebook登录");
    CS.XHgSdkAgent.SwitchAccount(XHgSdkManager.UserType.FaceBook);
end

-- function XHgSdkManager.LoginTourist()
--     XLog.Debug("SDK登录类型:游客登录")
--     CS.XHgSdkAgent.LoginTourist()
-- end

function XHgSdkManager.LoginTwitter()
    XLog.Debug("SDK登录类型:Twitter登录")
    -- CS.XHgSdkAgent.LoginTwitter()
    CS.XHgSdkAgent.SwitchAccount(XHgSdkManager.UserType.Twitter);
end

function XHgSdkManager.LoginLine()
    XLog.Debug("SDK登录类型:Line登录")
    -- CS.XHgSdkAgent.LoginLine()
    CS.XHgSdkAgent.SwitchAccount(XHgSdkManager.UserType.Line);
end

function XHgSdkManager.LoginApple()
    XLog.Debug("SDK登录类型:Apple登录")
    -- CS.XHgSdkAgent.LoginApple()
    CS.XHgSdkAgent.SwitchAccount(XHgSdkManager.UserType.Apple);
end

function XHgSdkManager.LoginHuawei()
    XLog.Debug("SDK登录类型:华为登录");
    CS.XHgSdkAgent.SwitchAccount(XHgSdkManager.UserType.Huawei);
end

function XHgSdkManager.LoginSid()
    XLog.Debug("SDK登录类型:引继码登录")
    CS.XHgSdkAgent.LoginSid()
end

function XHgSdkManager.LoginOppo()
    XLog.Debug("SDK登录类型:Oppo登录");
    CS.XHgSdkAgent.SwitchAccount(XHgSdkManager.UserType.Oppo);
end

local loginMethods = {
    [XHgSdkManager.UserType.Quickly] = XHgSdkManager.LoginQuickly,
    [XHgSdkManager.UserType.Vistor] = XHgSdkManager.LoginVisitor,
    [XHgSdkManager.UserType.Google] = XHgSdkManager.LoginGoogle,
    [XHgSdkManager.UserType.FaceBook] = XHgSdkManager.LoginFacebook,
    [XHgSdkManager.UserType.Apple] = XHgSdkManager.LoginApple,
    [XHgSdkManager.UserType.Twitter] = XHgSdkManager.LoginTwitter,
    [XHgSdkManager.UserType.Suid] = XHgSdkManager.LoginSid,
    [XHgSdkManager.UserType.Huawei] = XHgSdkManager.LoginHuawei,
    [XHgSdkManager.UserType.Oppo] = XHgSdkManager.LoginOppo,
    [XHgSdkManager.UserType.Line] = XHgSdkManager.LoginLine,
}

function XHgSdkManager.Login(userType)
    --if not checkNeedLogin() then return end
    if not checkLoginTimeTooFast() then return end
    CS.XRecord.Record("24023", "HeroSdkLogin")
    local loginMethod = loginMethods[userType]
    if loginMethod == nil then
        XLog.Error("登录类型未定义, userType=" .. userType)
        return
    end
    if XUserManager.Channel ~= XUserManager.CHANNEL.KuroPC then 
        XLuaUiManager.SetAnimationMask("HgLogin", true)
    end
    loginMethod()
end

function XHgSdkManager.LoginSuid(account, pass)
    --if not checkNeedLogin() then return end
    if not checkLoginTimeTooFast() then return end
    CS.XRecord.Record("24023", "HeroSdkLogin")
    XLog.Debug("SDK登录类型:引继码登录")
    XLuaUiManager.SetAnimationMask("HgLogin", true)
    CS.XHgSdkAgent.LoginSid(account, pass)
end

function XHgSdkManager.BackToLogin()
    CS.XRecord.Logout()
    XUserManager.SignOut()
    CleanPayCallbacks()
end

function XHgSdkManager.Logout()
    if XHgSdkManager.IsNeedLogin() then
        XLog.Debug("SDK无需登出")
        return
    end

    XLog.Debug("登出成功")
    CS.XHgSdkAgent.Logout()
    IsSdkLogined = false
    CS.XRecord.Record("24027", "HeroSdkLogoutSuccess")
    CS.XRecord.Record("24029", "HeroSdkLogout")
    CS.XRecord.Logout()
    XUserManager.SignOut()
    CleanPayCallbacks()
end

function XHgSdkManager.OnLoginSuccess(jsondata)
    XLog.Debug("SDK登录成功")
    --CheckPoint: APPEVENT_SDK_INITIALIZE
    XAppEventManager.AppLogEvent(XAppEventManager.CommonEventNameConfig.SDK_Initialize)
    XLuaUiManager.SetAnimationMask("HgLogin", false)
    IsSdkLogined = true
    XLog.Debug("--------------jsondata---------------")
    XLog.Debug(jsondata)
    local data = Json.decode(jsondata)

    local info = XRecordUserInfo()

    local userId = data.uid
    local userType = data.userType
    local pwdStatus = data.pwdStatus

    if XUserManager.Channel == XUserManager.CHANNEL.IOS then
        userId = data.suid
        userType = tonumber(data.type)
        pwdStatus = tonumber(data.pwdStatus)
    end

    info.UserId = userId
    CS.XRecord.Login(info)
    CS.XRecord.Record("24024", "HeroSdkLoginSuccess")
    CleanPayCallbacks()
    XUserManager.SetUserId(userId)
    XUserManager.SetToken(data.token)
    XUserManager.SetUserType(userType)
    XUserManager.SetPasswordStatus(pwdStatus)
    XLoginManager.SetSDKAccountStatus(tonumber(data.logoutStatus))
    if XLoginManager.GetSDKAccountStatus() == XLoginManager.SDKAccountStatus.Cancellation then
        XUiManager.DialogTip(CS.XGame.ClientConfig:GetString("AccountUnCancellationTitle"), CS.XGame.ClientConfig:GetString("AccountUnCancellationContent"), nil, function() end, function()
            XHgSdkManager.AccountUnCancellation()
        end)
    end
    XEventManager.DispatchEvent(XEventId.EVNET_HGSDKLOGIN_SUCCESS)
end

function XHgSdkManager.OnLoginFailed(msg)
    XLuaUiManager.SetAnimationMask("HgLogin", false)
    XLog.Debug("SDK登录失败: " .. msg)
    --IsSdkLogined = false
    CS.XRecord.Record("24032", "HeroSdkLoginFailed")
    LastTimeOfCallSdkLoginUi = 0
    if msg ~= nil and msg ~= "" then
        XUiManager.SystemDialogTip(CS.XTextManager.GetText("TipTitle"), msg, XUiManager.DialogType.OnlySure, nil, function()
            --XHgSdkManager.Login()
        end)
    end
end

function XHgSdkManager.OnLoginCancel(msg)
    XLuaUiManager.SetAnimationMask("HgLogin", false)
    XLog.Debug("SDK用户取消登录")
    --IsSdkLogined = false
    LastTimeOfCallSdkLoginUi = 0
    if msg ~= nil and msg ~= "" then
        XUiManager.SystemDialogTip(CS.XTextManager.GetText("TipTitle"), msg, XUiManager.DialogType.OnlySure, nil, function()
            --XHgSdkManager.Login()
        end)
    end
end

function XHgSdkManager.GetBindState()
    CS.XHgSdkAgent.GetBindState()
end

function XHgSdkManager.OnGetBindState(jsonStr)
    --{"code":0,"msg":"成功","fbBind":0,"googleBind":0,"gcBind":0,"weChatBind":0,"twitterBind":0,"appleBind":0,"lineBind":0}
    XEventManager.DispatchEvent(XEventId.EVENT_HGSDK_GET_BIND, jsonStr)
end

function XHgSdkManager.StartBind(userType)
    CS.XHgSdkAgent.StartBind(userType)
end

function XHgSdkManager.OnBindSuccess()
    XEventManager.DispatchEvent(XEventId.EVENT_HGSDK_BIND_RESULT, true)
end

function XHgSdkManager.OnBindFailed(msg)
    --{"code":2,"msg":"用户已经绑定其它帐号","userType":0}
    XEventManager.DispatchEvent(XEventId.EVENT_HGSDK_BIND_RESULT, false, msg)
end

function XHgSdkManager.OpenBindWindow()
    CS.XHgSdkAgent.OpenBindWindow()
end

function XHgSdkManager.SetSUidPass(pass)
    CS.XHgSdkAgent.SetSUidPassword(pass)
end

function XHgSdkManager.OnSetSUidPassSuccess()
    XEventManager.DispatchEvent(XEventId.EVENT_HGSDK_SETPASS_RESULT, true)
end

function XHgSdkManager.OnSetSUidPassFail()
    XEventManager.DispatchEvent(XEventId.EVENT_HGSDK_SETPASS_RESULT, false)
end

function XHgSdkManager.OnLoginUnRegister()
    CS.XHgSdkAgent.ShowRegister()
end

local GetOrderInfo = function(productKey, cpOrderId, goodsId, roleId)
    local orderInfo = HgOrderInfo()
    orderInfo.CpOrderId = cpOrderId
    orderInfo.GoodsId = goodsId
    orderInfo.RoleId = roleId
    orderInfo.RoleName = XPlayer.Name
    if CallbackUrl then
        orderInfo.CallbackUrl = CallbackUrl
    end
    if Platform == RuntimePlatform.WindowsPlayer 
    or Platform == RuntimePlatform.WindowsEditor then 
        local template = XPayConfigs.GetPayTemplate(productKey)
        orderInfo.Price = template.Amount
        orderInfo.GoodsName = template.Name
        orderInfo.ServerId = XServerManager.Id
        orderInfo.ServerName = XServerManager.ServerName
    end 
    return orderInfo
end

function XHgSdkManager.Pay(productKey, cpOrderId, goodsId, cb)
    if Platform == RuntimePlatform.Android or Platform == RuntimePlatform.WindowsPlayer 
    or Platform == RuntimePlatform.WindowsEditor then
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
    
    local order = GetOrderInfo(productKey, cpOrderId, goodsId, XPlayer.Id)
    CS.XHgSdkAgent.Pay(order)
end

function XHgSdkManager.OnPaySuccess(jsondata)
    local data = Json.decode(jsondata)
    local cpOrderId = data.cpOrderId
    local cbInfo = PayCallbacks[cpOrderId]
    if cbInfo and cbInfo.cb then
        cbInfo.cb(nil, cbInfo.info)
    else
        --XLog.Debug("XHgSdkManager.OnPaySuccess is nil")
    end
    PayCallbacks[cpOrderId] = nil
end

function XHgSdkManager.OnPayFailed(jsondata)
    local data = Json.decode(jsondata)
    local cpOrderId = data.cpOrderId
    local msg = data.msg or ""
    local cbInfo = PayCallbacks[cpOrderId]
    if cbInfo and cbInfo.cb then
        cbInfo.cb(msg, cbInfo.info)
    else
        --XLog.Debug("XHgSdkManager.OnPayFailed is nil")
    end
    PayCallbacks[cpOrderId] = nil
    --支付失败的时候解锁
    XEventManager.DispatchEvent(XEventId.EVENT_PURCHASEBUY_PAYCANCELORFAIL)
end

function XHgSdkManager.OnPayCancel(cpOrderId, msg)
    --PayCallbacks[cpOrderId] = nil
    local text = CS.XTextManager.GetText("PayFail")
    XUiManager.DialogTip("", text, XUiManager.DialogType.OnlySure)
    XEventManager.DispatchEvent(XEventId.EVENT_PURCHASEBUY_PAYCANCELORFAIL)
end

function XHgSdkManager.OnPayPending(cpOrderId, msg)
    --XLog.Debug("XHgSdkManager.OnPayPending")
    --XLog.Debug(cpOrderId)
    --XLog.Debug(msg)
end

function XHgSdkManager.OnPayResultNull()
    XEventManager.DispatchEvent(XEventId.EVENT_PURCHASEBUY_PAYCANCELORFAIL)
end

function XHgSdkManager.OnPayIOSSuccess(jsondata)
    local data = Json.decode(jsondata)
    local cpOrderId = data.cpOrderId
    if IOSPayCallback then
        IOSPayCallback(nil, cpOrderId)
    end
end

function XHgSdkManager.OnPayIOSFailed(jsondata)
    local data = Json.decode(jsondata)
    local msg = data.msg or ""
    if IOSPayCallback then
        IOSPayCallback(msg)
    end
    --支付失败的时候解锁
    XEventManager.DispatchEvent(XEventId.EVENT_PURCHASEBUY_PAYCANCELORFAIL)
end

function XHgSdkManager.OnPayPCSuccess(jsondata)
    local data = Json.decode(jsondata)
    local cpOrderId = data.cpOrder
    local cbInfo = PayCallbacks[cpOrderId]
    if cbInfo and cbInfo.cb then
        cbInfo.cb(nil, cbInfo.info)
    else
        --XLog.Debug("XHgSdkManager.OnPaySuccess is nil")
    end
    PayCallbacks[cpOrderId] = nil
end

function XHgSdkManager.OnPayPCFailed(jsondata)
    local data = Json.decode(jsondata)
    local cpOrderId = data.cpOrder
    local msg = data.msg or ""
    local cbInfo = PayCallbacks[cpOrderId]
    if cbInfo and cbInfo.cb then
        cbInfo.cb(msg, cbInfo.info)
    else
        --XLog.Debug("XHgSdkManager.OnPayFailed is nil")
    end
    PayCallbacks[cpOrderId] = nil
    --支付失败的时候解锁
    XEventManager.DispatchEvent(XEventId.EVENT_PURCHASEBUY_PAYCANCELORFAIL)
end

function XHgSdkManager.RegisterIOSCallback(cb)
    IOSPayCallback = cb
end

function XHgSdkManager.OnRegisterAccountFailed(msg)
    
end

function XHgSdkManager.OnSwitchAccountResultNull()
    
end

function XHgSdkManager.OnSwitchAccountNoRegister(uid, token, pwdStatus, msg)
    
end

function XHgSdkManager.OnRegisterAccountResultNull(msg)
    
end

function XHgSdkManager.OnRegisterAccountSuccess(uid, token, userType)
    
end

function XHgSdkManager.OnRegisterAccountCancel()
    
end

function XHgSdkManager.OnStartBindResultSuccess()
    
end

function XHgSdkManager.OnStartBindResultNull()
    
end

function XHgSdkManager.OnStartBindResultCancel()
    
end

function XHgSdkManager.OnStartBindResultFailed()
    
end

function XHgSdkManager.OnBindTaskFinished()
    local taskParam = XTaskConfig.GetTaskCondition(3000190).Params[2]
    XNetwork.Call("DoClientTaskEventRequest", {ClientTaskType = taskParam}, function(reply)
        if reply.Code ~= XCode.Success then
            return
        end
        XLog.Debug("引继码任务完成")
    end)
end

local BdcServerBean

function XHgSdkManager.setServerBeanTmp(serverBean)
    BdcServerBean  = serverBean
end

function XHgSdkManager.onServerBeanChangeHandle()
    local jsonBdcServerBean = CS.XHeroBdcAgent.GetServerBeanStr()
    if jsonBdcServerBean and jsonBdcServerBean ~= "" then
        if not BdcServerBean or jsonBdcServerBean ~= BdcServerBean then
            BdcServerBean = jsonBdcServerBean
            if XLoginManager.IsLogin() then
                XLog.Warning("ServerBean数据同步")
                XNetwork.Call("SetServerBeanRequest", {ServerBean = BdcServerBean}, function(reply)
                    if reply.Code ~= XCode.Success then
                        XLog.Error(reply.Code)
                        return
                    end
                end) 
            end
        end
    end
    XLog.Warning("ServerBean修改", jsonBdcServerBean)
end

function XHgSdkManager.AccountCancellation()
    XLog.Debug("Lua层调用注销账号")
    if Platform == RuntimePlatform.IPhonePlayer then -- 目前只有ios存在账号注销功能
        CS.XHgSdkAgent.AccountCancellation()
    end
end

function XHgSdkManager.AccountUnCancellation()
    XLog.Debug("Lua层调用取消注销账号")
    if Platform == RuntimePlatform.IPhonePlayer then -- 目前只有ios存在该功能
        CS.XHgSdkAgent.AccountUnCancellation()
    end
end

function XHgSdkManager.SwitchAccount(userType)
    XLog.Debug("SDK开始切换账户");
    CS.XHgSdkAgent.SwitchAccount(userType);
end

function XHgSdkManager.reportAccountInfo(serverId,roleId,cpExt)
    if Platform == RuntimePlatform.Android then
        CS.XHgSdkAgent.reportAccountInfo(serverId,roleId,cpExt)
    end
end
-- 注销账号成功回调
function XHgSdkManager.OnAccountCancellationSuccess()
    XLog.Debug("Lua层注销账号成功回调")
    XUserManager.Logout() -- 登出
end

-- 取消注销账号回调
function XHgSdkManager.OnAccountUnCancellation(flag)
    XLog.Debug("Lua层取消注销账号回调:"..tostring(flag))
    if flag == "success" then
        XLoginManager.SetSDKAccountStatus(XLoginManager.SDKAccountStatus.Normal)
        XUiManager.TipMsg(CS.XGame.ClientConfig:GetString("OnAccountUnCancellationSuccessTip"))
    end
end

function XHgSdkManager.OnBdcServerBeanChanged()
    if not XLoginManager.IsLogin() then return end -- 如果没登入服务器，不检测bdcServerBean改变，登录时会重新向服务器发送
    local serverBean = CS.XHeroBdcAgent.GetServerBeanStr()
    if serverBean and serverBean ~= "" then
        XNetwork.Call("SetServerBeanRequest", {ServerBean = serverBean}, function(res)
            if res.Code ~= XCode.Success then
                XLog.Error("SetServerBeanRequest Error")
                return
            end
        end)
    else
        XLog.Error("Lua OnBdcServerBeanChanged ServerBean is Nil")
    end
end

function XHgSdkManager.GetDeepLinkValue()
    if not deepLinkValue or deepLinkValue == "" then
        deepLinkValue = CS.XAppsflyerEvent.GetDeepLinkValue()
    end
    if deepLinkValue and deepLinkValue ~= "" then
        XLog.Debug("DeepLinkValue:"..tostring(deepLinkValue))
        return deepLinkValue
    end
end

function XHgSdkManager.PushDeepLinkEvent()
    local deepLinkValue = XHgSdkManager.GetDeepLinkValue()
    if CS.XRemoteConfig.AFDeepLinkEnabled and not string.IsNilOrEmpty(deepLinkValue) then
        if XLuaUiManager.IsUiShow("UiLogin") then -- 登录界面唤醒自动登录
            XEventManager.DispatchEvent(XEventId.EVENT_DEEPLINK_PUSH_TO_LOGIN)
        elseif XLuaUiManager.IsUiShow("UiMain") then -- 主界面直接跳转
            XEventManager.DispatchEvent(XEventId.EVENT_MAINUI_ENABLE)
        else
            XHgSdkManager.ClearDeepLinkValue()
        end
    end
end