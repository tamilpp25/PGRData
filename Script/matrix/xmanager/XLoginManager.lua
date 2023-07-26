XLoginManager = XLoginManager or {}

local Json = require("XCommon/Json")
local RetCode = {
    Success = 0,
    LoginServiceInvalidToken = 4, -- 登录token失效
    ErrServerMaintaining = 1, -- 服务器正常维护
    ServerIsFull = 9, --服务器满员
    FirstLoginIsBanned = 11, -- 初次封禁
    MultiLoginIsBanned = 12, -- 多次封禁
}


local NEW_PLAYER_FLAG = 1 << 0
local SinceStartupTime = function() return CS.UnityEngine.Time.realtimeSinceStartup end
local SinceStartupMilliSeconds = function() return math.floor(CS.UnityEngine.Time.realtimeSinceStartup * 1000) end

local TableLoginErrCode = "Share/Login/LoginCode.tab"
local TableLoginProtect = "Client/Login/LoginProtect.tab"
local LoginErrCodeTemplate
local LoginProtectTemplate

-- 登陆token缓存
local LoginTokenCache

local UI_LOGIN = "UiLogin"
local OnLogin
local LoginCb
local IsConnected = false
local IsLogin = false
local IsRelogining = false
local FirstOpenMainUi = false    --首次登陆成功打开主界面
local StartGuide = false --首次进入主界面播放完成动画后才能开始引导
local LimitLoginQuiz = {}
local HeartbeatIntervalDefault = CS.XGame.Config:GetInt("HeartbeatInterval")
local HeartbeatInterval = HeartbeatIntervalDefault
local HeartbeatTimeout = CS.XGame.Config:GetInt("HeartbeatTimeout")
local HeartbeatTimeOutTimer = nil
local HeartbeatNextTimer = nil
local ClearHeartbeartTimer
local ClearTimeOutTimer
local MaxDisconnectTime = CS.XGame.Config:GetInt("MaxDisconnectTime") --最大断线重连时间（服务器保留时间）
local ReconnectInterval = CS.XGame.Config:GetInt("ReconnectInterval") --重连间隔
local DelayReconnectTime = CS.XGame.Config:GetInt("DelayReconnectTime") --延迟重连时间

local GateHandshakeTimer
local ReconnectTimer
local MaxReconnectTimer

local LoginTimeOutSecond = CS.XGame.Config:GetInt("LoginTimeOutInterval")
local LoginTimeOutInterval = LoginTimeOutSecond * 1000
local LoginTimeOutTimer
local LoginNetworkError = CS.XTextManager.GetText("LoginNetworkError")
local LoginHttpError = CS.XTextManager.GetText("LoginHttpError")

local RetryLoginCount = 0 
local RETRY_LOGIN_MAX_COUNT = 3
local ServerFullRetryLoginCount = 0 --服务器满员/繁忙重试次数
local ServerFullRetryLoginCacheKey = "ServerFullRetryLoginCacheKey" --服务器满员/繁忙重试次数 缓存Key
local ServerFullRetryCountDown = 0 --服务器满员/繁忙登录保护倒计时
local ServerFullNRestTime = CS.XGame.ClientConfig:GetInt("ServerFullNRestTime") --服务器满员/繁忙情况下，重置RetryLoginCount时间，单位：秒

-- 声明local方法
-- local DoReconnect
local DelayReconnect
local StartReconnect
-- local CreateKcpSession
-- local DoKcpHeartbeat
local DoMtpLogin    --腾讯反外挂

local PingInterval = 1 * 60 * 1000
local PingDelay = 30 * 1000

local TcpPingTimer
local StartTcpPingGate = function()
    if TcpPingTimer then
        XScheduleManager.UnSchedule(TcpPingTimer)
    end
    TcpPingTimer = XScheduleManager.ScheduleForever(function()
        CS.XNetTool.PingGateTcp()
    end, PingInterval, PingDelay)
end

local NetworkEvent = {}
NetworkEvent.ConnectCb = "ConnectCb"
NetworkEvent.DisconnectCb = "DisconnectCb"
NetworkEvent.ReconnectRequestFrequentlyCb = "ReconnectRequestFrequentlyCb"
NetworkEvent.RemoteDisconnectCb = "RemoteDisconnectCb"
NetworkEvent.MsgErrorCb = "MsgErrorCb"
NetworkEvent.RemoveHandshakeTimerCb = "RemoveHandshakeTimerCb"


local function OnNetworkCB(eventName, param)
    -- XLog.Debug(">> OnNetworkCB, IsRelogining:" .. tostring(IsRelogining) .. ", eventName：" .. eventName ..", param:" .. tostring(param))
    if eventName == NetworkEvent.ConnectCb then
        --BDC
        CS.XHeroBdcAgent.BdcServiceState(XServerManager.Id, "1")
        CS.XHeroBdcAgent.IntoGameTimeStart = CS.UnityEngine.Time.time
        IsConnected = true
        local cb = param
        cb()
        
    elseif eventName == NetworkEvent.DisconnectCb then
        IsConnected = false
        -- IsRehandedKcp = false
        OnLogin(XCode.Fail)
    elseif eventName == NetworkEvent.ReconnectRequestFrequentlyCb then
        DelayReconnect()

    elseif eventName == NetworkEvent.RemoteDisconnectCb then
        XLoginManager.DoReconnect()

    elseif eventName == NetworkEvent.ErrorCb then
        --BDC
        CS.XHeroBdcAgent.BdcServiceState(XServerManager.Id, "2")
        local err = param
        if err and (err ~= CS.System.Net.Sockets.SocketError.Success and err ~= CS.System.Net.Sockets.SocketError.OperationAborted) then
            local errStr = tostring(err:ToString())
            XLog.Warning("XNetwork.ConnectGateServer error. ============ SocketError." .. errStr)
            local msgtab = {}
            msgtab.error = errStr
            CS.XRecord.Record(msgtab, "24013", "ConnectGateSeverSocketError")
            if LoginCb and not IsRelogining then
                XLuaUiManager.ClearAnimationMask()
                XUiManager.SystemDialogTip(CS.XTextManager.GetText("TipTitle"), CS.XTextManager.GetText("NetworkError"), XUiManager.DialogType.OnlySure, nil, nil)
                OnLogin(XCode.Fail)
            end
        end

    elseif eventName == NetworkEvent.MsgErrorCb then
        if ReconnectTimer then
            XScheduleManager.UnSchedule(ReconnectTimer)
            ReconnectTimer = nil
        end
        if MaxReconnectTimer then
            XScheduleManager.UnSchedule(MaxReconnectTimer)
        end
        XLoginManager.DoDisconnect()

    elseif eventName == NetworkEvent.RemoveHandshakeTimerCb then
        if GateHandshakeTimer then
            XScheduleManager.UnSchedule(GateHandshakeTimer)
            GateHandshakeTimer = nil
        end
    end
end

local ConnectGate = function(cb, bReconnect)
    cb = cb or function()
    end

    if IsConnected then
        cb()
        return
    end

    local args = {}
    args.ConnectCb                    = function() OnNetworkCB(NetworkEvent.ConnectCb, cb) end
    args.DisconnectCb                 = function() OnNetworkCB(NetworkEvent.DisconnectCb) end
    args.ReconnectRequestFrequentlyCb = function() OnNetworkCB(NetworkEvent.ReconnectRequestFrequentlyCb) end
    args.RemoteDisconnectCb           = function() OnNetworkCB(NetworkEvent.RemoteDisconnectCb) end
    args.ErrorCb                      = function(err) OnNetworkCB(NetworkEvent.ErrorCb, err) end
    args.MsgErrorCb                   = function() OnNetworkCB(NetworkEvent.MsgErrorCb) end
    args.RemoveHandshakeTimerCb       = function() OnNetworkCB(NetworkEvent.RemoveHandshakeTimerCb) end
    args.IsReconnect = bReconnect
    XNetwork.ConnectGateServer(args)
end

function XLoginManager.Disconnect(bReconnect)
    ClearHeartbeartTimer()

    CS.XNetwork.Disconnect()
    IsConnected = false

    if not bReconnect then --  断线重连不重设状态
        IsLogin = false
    end

    -- XLog.Debug(" 调用断开连接 LoginCb:" .. tostring(LoginCb) )
    OnLogin(XCode.Fail)

    XEventManager.DispatchEvent(XEventId.EVENT_NETWORK_DISCONNECT)
end

-- 主动断开连接
function XLoginManager.DoDisconnect(text)
    if XNetwork.IsShowNetLog then
        XLog.Debug("DoDisconnect.")
    end

    if IsRelogining then
        return
    end
    
    XLoginManager.Disconnect()
    XLoginManager.ClearAllTimer()
    XLuaUiManager.ClearAllMask(true)
    CS.XRecord.Record("24014", "SocketDisconnect")

    if XDataCenter.FunctionEventManager.CheckFuncDisable() then
        XLoginManager.BackToLogin()
    else
        XUiManager.SystemDialogTip(CS.XTextManager.GetText("TipTitle"), text or CS.XTextManager.GetText("HeartbeatTimeout"), XUiManager.DialogType.OnlySure, nil, XLoginManager.BackToLogin)
    end

    XEventManager.DispatchEvent(XEventId.EVENT_USER_LOGOUT)
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_USER_LOGOUT)
end


function XLoginManager.ClearGame()
    -- 清除业务模块
    XFightUtil.ClearFight()
    if XDataCenter.MovieManager then
        XDataCenter.MovieManager.StopMovie()
    end
    CS.Movie.XMovieManager.Instance:Clear()
    CsXUiManager.Instance:Clear()
    XHomeSceneManager.LeaveScene()
end

-- 清理返回登陆界面
function XLoginManager.BackToLogin()
    -- 清除所有定时器
    XLoginManager.ClearAllTimer()
    XDataCenter.InitBeforeLogin()

    -- 断开socket连接
    CS.XNetwork.Disconnect()
    
    -- 重设状态
    IsConnected = false
    IsLogin = false
    IsRelogining = false

    XLoginManager.ClearGame()

    XLuaUiManager.Open(UI_LOGIN)
end

-- 清理返回主界面
function XLoginManager.BackToMain()
    XLoginManager.ClearGame()
    XLuaUiManager.RunMain(true)
end

local DoHeartbeat
local HearbeatRequestTime


local function CheckHeartbeatTimeout()
    if XNetwork.IsShowNetLog then
        XLog.Debug("tcp heartbeat time out.")
    end
    StartReconnect()
end

function ClearHeartbeartTimer()
    if HeartbeatTimeOutTimer then
        XScheduleManager.UnSchedule(HeartbeatTimeOutTimer)
        HeartbeatTimeOutTimer = nil
    end

    if HeartbeatNextTimer then
        XScheduleManager.UnSchedule(HeartbeatNextTimer)
        HeartbeatNextTimer = nil
    end
end

local function OnHeartbeatResp(res)
    XTime.SyncTime(res.UtcServerTime, HearbeatRequestTime, SinceStartupTime())

    ClearHeartbeartTimer()
    -- if XNetwork.IsShowNetLog then
    --     XLog.Debug("tcp heartbeat response.")
    -- end
    -- 等待下一次心跳发送
    HeartbeatNextTimer = XScheduleManager.ScheduleOnce(DoHeartbeat, HeartbeatInterval)
end

DoHeartbeat = function()
    HeartbeatNextTimer = nil

    if not IsLogin then
        return
    end

    -- if XNetwork.IsShowNetLog then
    --     XLog.Debug("tcp heartbeat request.")
    -- end
    -- 等待心跳返回
    HeartbeatTimeOutTimer = XScheduleManager.ScheduleOnce(CheckHeartbeatTimeout, HeartbeatTimeout)

    HearbeatRequestTime = SinceStartupTime()
    XNetwork.Call("HeartbeatRequest", nil, OnHeartbeatResp)
end

StartReconnect = function()
    CS.XRecord.Record("24033", "StartReconnect");
    local startReconnectTime = SinceStartupTime()

    if MaxReconnectTimer then
        XScheduleManager.UnSchedule(MaxReconnectTimer)
        MaxReconnectTimer = nil
    end

    MaxReconnectTimer = XScheduleManager.ScheduleForever(function()
        if SinceStartupTime() - startReconnectTime > MaxDisconnectTime then
            if XNetwork.IsShowNetLog then
                XLog.Debug("超过服务器保留最长时间")
            end
            ClearHeartbeartTimer()
            XScheduleManager.UnSchedule(MaxReconnectTimer)
            XLoginManager.DoDisconnect()
        end
    end, 1000)
    XLoginManager.DoReconnect()
end

DelayReconnect = function()
    if IsRelogining then
        XLog.Debug(" IsRelogining DelayReconnect return ")
        return
    end
    if XNetwork.IsShowNetLog then
        XLog.Debug("重连频繁异常，延后再重连.")
    end

    if ReconnectTimer then
        XScheduleManager.UnSchedule(ReconnectTimer)
        ReconnectTimer = nil
    end

    ReconnectTimer = XScheduleManager.ScheduleOnce(function()
        CS.XNetwork.Disconnect()
        XLoginManager.DoReconnect()
    end, DelayReconnectTime)
end

-- 断线重连方法
function XLoginManager.DoReconnect()
    if IsRelogining then
        XLog.Debug(" IsRelogining DoReconnect return ")
        return
    end
    if not IsLogin then
        XLoginManager.Disconnect()
        return
    end

    if not XUserManager.ReconnectedToken then
        XLoginManager.DoDisconnect()
        return
    end

    ReconnectTimer = XScheduleManager.ScheduleOnce(function()
        if XNetwork.IsShowNetLog then
            XLog.Debug("断线重连响应超时")
        end
        CS.XNetwork.Disconnect()
        XLoginManager.DoReconnect()
    end, ReconnectInterval)

    if XNetwork.IsShowNetLog then
        XLog.Debug("开始断线重连...")
    end
    XLoginManager.Disconnect(true)
    --重连网关
    ConnectGate(function()
        XLog.Debug("ConnectGate succ:")
        if ReconnectTimer then
            XScheduleManager.UnSchedule(ReconnectTimer)
            ReconnectTimer = nil
        end
        if XNetwork.IsShowNetLog then
            XLog.Debug("reconnect, then request heart beat.")
        end
        if MaxReconnectTimer then
            XScheduleManager.UnSchedule(MaxReconnectTimer)
            MaxReconnectTimer = nil
        end
        DoMtpLogin(XUserManager.UserId, XUserManager.UserName)
        DoHeartbeat()
    end, true)
end

DoMtpLogin = function(uid, username)
    CS.XMtp.Login(uid, username)
end

local OnLoginSuccess = function()
    CS.XRecord.Record("24018", "OnLoginSuccess")
    IsLogin = true
    if XNetwork.IsShowNetLog then
        XLog.Debug("login success, then request heart beat.")
    end
    DoMtpLogin(XUserManager.UserId, XUserManager.UserName)
    DoHeartbeat()
    StartTcpPingGate()
    XEventManager.DispatchEvent(XEventId.EVENT_LOGIN_SUCCESS)
    CS.XGameEventManager.Instance:Notify(XEventId.EVENT_LOGIN_SUCCESS)
end

OnLogin = function(errCode)
    ClearTimeOutTimer()

    if not errCode or errCode == XCode.Success then
        OnLoginSuccess()
    else
        CS.XRecord.Record("24015", "OnLoginError")
    end
    if LoginCb then
        LoginCb(errCode)
        LoginCb = nil
    end
end

local DoLoginTimeOut = function(cb)
    XLoginManager.Disconnect()
    XLuaUiManager.ClearAnimationMask()
    CS.XRecord.Record("24016", "DoLoginTimeOut")
    XUiManager.SystemDialogTip(CS.XTextManager.GetText("TipTitle"), CS.XTextManager.GetText("LoginTimeOut"), XUiManager.DialogType.Normal, function()
        OnLogin(XCode.Fail)
    end, function()
        XLoginManager.Login(cb)
    end)
end

--region   ------------------服务器满员登录保护 start-------------------
local initUserId
local GetCookiesKey = function(key) 
    return string.format("XLoginManager.GetCookiesKey_%s_%s", XUserManager.UserId, key)
end

--==============================
---@desc 获取小于重试次数的最大登录次数
---@return table
--==============================
local FindLessCountWithMaxLoginTimes = function()
    local tmp
    for id = 1, #LoginProtectTemplate do
        local cfg = LoginProtectTemplate[id]
        if cfg and cfg.LoginTime <= ServerFullRetryLoginCount then
            tmp = cfg
        end
    end
    return tmp
end

--==============================
 ---@desc 获取下次能成功登录的间隔
 ---@return number
--==============================
local GetNextLoginInterval = function()
    local key = GetCookiesKey("ServerFullLoginInterval")
    local timeStamp = XSaveTool.GetData(key) or XTime.GetLocalNowTimestamp()
    return tonumber(timeStamp)
end

--==============================
 ---@desc 设置下次登录的间隔
 ---@timeStamp number 
--==============================
local SaveNextLoginInterval = function(timeStamp)
    local key = GetCookiesKey("ServerFullLoginInterval")
    XSaveTool.SaveData(key, timeStamp)
end

--==============================
 ---@desc 获取第一次登录 服务器满员/繁忙的时间
 ---@return number
--==============================
local GetFirstLoginErrorTime = function()
    local key = GetCookiesKey("ServerFullRetryLoginCountResetTime")
    local firstLoginErrTime = XSaveTool.GetData(key)
    return firstLoginErrTime and tonumber(firstLoginErrTime) or 0
end

--==============================
 ---@desc 设置第一次登录 服务器满员/繁忙的时间
 ---@timeStamp number 
--==============================
local SetFirstLoginErrorTime = function(timeStamp)
    local key = GetCookiesKey("ServerFullRetryLoginCountResetTime")
    local firstLoginErrTime = XSaveTool.GetData(key)
    if firstLoginErrTime then
        return
    end
    XSaveTool.SaveData(key, timeStamp)
end

--==============================
 ---@desc 重置 登陆错误时间
--==============================
local ResetFirstLoginErrorTime = function()
    local key = GetCookiesKey("ServerFullRetryLoginCountResetTime")
    XSaveTool.RemoveData(key)
end

--==============================
 ---@desc 重置登录重试次数
--==============================
local ResetLoginOnServerFull = function()
    ServerFullRetryLoginCount = 0
    XSaveTool.SaveData(GetCookiesKey(ServerFullRetryLoginCacheKey), 0)
    ResetFirstLoginErrorTime()
end

--==============================
 ---@desc 服务器满员保护
 ---@return string
--==============================
local DoLoginOnServerFull = function()
    local tmp = FindLessCountWithMaxLoginTimes()
    ServerFullRetryCountDown = tmp.Interval
    SaveNextLoginInterval(XTime.GetLocalNowTimestamp())
    ServerFullRetryLoginCount = ServerFullRetryLoginCount + 1
    XSaveTool.SaveData(GetCookiesKey(ServerFullRetryLoginCacheKey), ServerFullRetryLoginCount)
    if ServerFullRetryLoginCount > 0 then
        SetFirstLoginErrorTime(XTime.GetLocalNowTimestamp())
    end
    return tmp.Hint
end

--==============================
 ---@desc 本地数据--第一次登录初始化登录保护相关
--==============================
local InitServerFullProtectConfig = function()
    if not initUserId or XUserManager.UserId ~= initUserId then
        local cacheData = XSaveTool.GetData(GetCookiesKey(ServerFullRetryLoginCacheKey))
        ServerFullRetryLoginCount = cacheData and tonumber(cacheData) or 0
        local tmp = FindLessCountWithMaxLoginTimes()
        ServerFullRetryCountDown = tmp.Interval
        initUserId = XUserManager.UserId
    end
end

--==============================
 ---@desc 检查是否需要清除RestN，并重置N，每次登录前检查
--==============================
local DoCheckNeedResetLoginErrorTime = function()
    if ServerFullRetryLoginCount > 0 then
        local time = GetFirstLoginErrorTime()
        local now = XTime.GetLocalNowTimestamp()
        if now - time >= ServerFullNRestTime then
            ResetLoginOnServerFull()
        end
    end
end

--==============================
 ---@desc 检查登录倒计时是否完成
 ---@return boolean
--==============================
local CheckIsLoginCountDown = function()
    if ServerFullRetryCountDown > 0 then
        local now = XTime.GetLocalNowTimestamp()
        local errTime = GetNextLoginInterval()
        local subTime = now - errTime
        if subTime >= ServerFullRetryCountDown then
            ServerFullRetryCountDown = 0
            return false
        end
    else
        return false
    end
    return true
end

--endregion------------------服务器满员登录保护 finish------------------


function XLoginManager.DoLogin(cb)
    local projectId = CS.XHeroSdkAgent.GetAppProjectId()
    XLog.Debug("channel:" .. tostring(XUserManager.Channel) .. "," .. tostring(CS.XRemoteConfig.Channel) .. ", userId:" .. tostring(XUserManager.UserId) .. ", AppProjectId:" .. tostring(projectId))

    if XUserManager.Channel == nil or XUserManager.UserId == nil then
        return
    end
    --第一次登录，初始化
    InitServerFullProtectConfig()
    --XLog.Debug("登录保护：", "（服务器繁忙/爆满）重登失败次数：" .. ServerFullRetryLoginCount, 
    --        "第一次登录失败时间: " .. XTime.TimestampToLocalDateTimeString(GetFirstLoginErrorTime()), 
    --        "次数重置时间：" .. XTime.TimestampToLocalDateTimeString(GetFirstLoginErrorTime() + ServerFullNRestTime))
    --登录冷却中
    if CheckIsLoginCountDown() then
        local tmp = FindLessCountWithMaxLoginTimes()
        XUiManager.SystemDialogTip("", tmp.Hint, XUiManager.DialogType.OnlySure, nil, function()
            OnLogin(XCode.Fail)
        end)

        return
    end
    
    --判断是否需要重置第一次登录错误的时间
    DoCheckNeedResetLoginErrorTime()

    local loginUrl = XServerManager.GetLoginUrl() ..
    "?loginType=" .. XUserManager.Channel ..
    "&userId=" .. XUserManager.UserId ..
    "&projectId=" .. (projectId or "") ..
    "&token=" .. (XUserManager.Token or "") ..
    "&deviceId=" .. CS.XHeroBdcAgent.GetDeviceId()

    XLog.Debug("LoginUrl = " .. loginUrl)
    local request = CS.UnityEngine.Networking.UnityWebRequest.Get(loginUrl)
    request.timeout = LoginTimeOutSecond
    CS.XRecord.Record("24009", "RequestLoginHttpSever")
    XLuaUiManager.SetAnimationMask("RequestLoginHttpSever", true)
    CS.XTool.WaitNativeCoroutine(request:SendWebRequest(), function()
        if IsRelogining then
            if request.isNetworkError or request.isHttpError then
                OnLogin(XCode.Fail)
                return
            end
        end
        if request.isNetworkError then
            XLog.Error("login network error，url is " .. loginUrl .. ", message is " .. request.error)
            XLuaUiManager.SetAnimationMask("RequestLoginHttpSever", false)
            XUiManager.SystemDialogTip("", LoginNetworkError, XUiManager.DialogType.OnlySure, nil, function()
                OnLogin(XCode.Fail)
            end)
            CS.XRecord.Record("24010", "RequestLoginHttpSeverNetWorkError")
            return
        end

        if request.isHttpError then
            XLog.Error("login http error，url is " .. loginUrl .. ", message is " .. request.error)
            XLuaUiManager.SetAnimationMask("RequestLoginHttpSever", false)
            XUiManager.SystemDialogTip("", LoginHttpError, XUiManager.DialogType.OnlySure, nil, function()
                OnLogin(XCode.Fail)
            end)
            CS.XRecord.Record("24011", "RequestLoginHttpSeverHttpError")
            return
        end

        local result = Json.decode(request.downloadHandler.text)
        if result.code ~= RetCode.Success then
            if IsRelogining then
                OnLogin(XCode.Fail)
                return
            end
        end

        if result.code ~= RetCode.Success then
            local tipMsg

            if result.code == RetCode.ErrServerMaintaining then
                tipMsg = result.msg
            elseif result.code == RetCode.FirstLoginIsBanned or result.code == RetCode.MultiLoginIsBanned then
                local template = LoginErrCodeTemplate[result.code]
                local timeStr = os.date("%Y-%m-%d %H:%M:%S", result.loginLockTime)
                tipMsg = string.format(template.Msg, result.playerId, result.reason, timeStr)
            elseif result.code == RetCode.ServerIsFull then
                tipMsg = DoLoginOnServerFull()
            else
                local template = LoginErrCodeTemplate[result.code]
                if template then
                    tipMsg = template.Msg
                else
                    tipMsg = "login errCode is " .. result.code
                end
            end

            XLuaUiManager.SetAnimationMask("RequestLoginHttpSever", false)
            XUiManager.SystemDialogTip("", tipMsg, XUiManager.DialogType.OnlySure, nil, function()
                if LoginCb then
                    -- 如果是登录失效的话，需要注销登录
                    if result.code == RetCode.LoginServiceInvalidToken then 
                        OnLogin(XCode.LoginServiceInvalidToken)
                    else
                        OnLogin(XCode.Fail)
                    end
                end
            end)
            CS.XRecord.Record("24012", "RequestLoginHttpSeverLoginError")
            return
        end

        XLuaUiManager.SetAnimationMask("RequestLoginHttpSever", false)
        CS.XRecord.Record("24031", "RequestLoginHttpSeverLoginSuccess")
        if cb then
            cb(result.token, result.ip, result.host, result.port)
        end

        request:Dispose()
    end)
end


function ClearTimeOutTimer()
    if LoginTimeOutTimer then
        XScheduleManager.UnSchedule(LoginTimeOutTimer)
        LoginTimeOutTimer = nil
    end
end

function XLoginManager.ClearAllTimer()
    ClearHeartbeartTimer()
    ClearTimeOutTimer()

    if GateHandshakeTimer then
        XScheduleManager.UnSchedule(GateHandshakeTimer)
        GateHandshakeTimer = nil
    end

    if ReconnectTimer then
        XScheduleManager.UnSchedule(ReconnectTimer)
        ReconnectTimer = nil
    end

    if MaxReconnectTimer then
        XScheduleManager.UnSchedule(MaxReconnectTimer)
        MaxReconnectTimer = nil
    end

    if TcpPingTimer then
        XScheduleManager.UnSchedule(TcpPingTimer)
        TcpPingTimer = nil
    end
end

function XLoginManager.DoLoginGame(cb)
    ClearTimeOutTimer()

    LoginTimeOutTimer = XScheduleManager.ScheduleOnce(function()
        DoLoginTimeOut(cb)
    end, LoginTimeOutInterval)

    XLog.Debug("login platform is " .. XUserManager.Platform)
    -- BDC设置ServerBean，更新追加的
    if XUserManager.Platform == XUserManager.PLATFORM.Android or XUserManager.Platform == XUserManager.PLATFORM.IOS then 
        XNetwork.Call("SetServerBeanRequest", {
            ServerBean = CS.XHeroBdcAgent.GetServerBean(),
        }, function(res)
            if res.Code ~= XCode.Success then
                XLog.Error("SetServerBeanRequest return error: " .. tostring(res.Code))
            end
        end)
    end
    
    local reqTime = SinceStartupTime()
    XNetwork.Call("LoginRequest", {
        LoginType = XUserManager.Channel,
        LoginPlatform = XUserManager.Platform,
        UserId = XUserManager.UserId,
        ProjectId = CS.XHeroSdkAgent.GetAppProjectId(),
        Token = LoginTokenCache,
        DeviceId = CS.XHeroBdcAgent.GetDeviceId(),
        OaId = CS.XHeroSdkAgent.OAID,
        ClientVersion = CS.XRemoteConfig.DocumentVersion,
    }, function(res)
        if res.Code ~= XCode.Success then
            if IsRelogining then
                OnLogin(res.Code)
                return
            end
        end

        if res.Code ~= XCode.Success then
            --BDC
            CS.XHeroBdcAgent.BdcRoleLogin("1", "")
            if res.Code == XCode.LoginServiceRetry and RetryLoginCount < RETRY_LOGIN_MAX_COUNT then
                RetryLoginCount = RetryLoginCount + 1
                local msgtab = {}
                msgtab.retry_login_count = RetryLoginCount
                CS.XRecord.Record(msgtab, "24017", "DoLoginGameRequestError")
                XLoginManager.DoLoginGame(cb)
            elseif res.Code == XCode.GameServerFullLoad then
                local msgtab = {}
                msgtab.retry_login_count = ServerFullRetryLoginCount
                CS.XRecord.Record(msgtab, "24017", "DoLoginGameRequestError")
                local tips = DoLoginOnServerFull()
                XUiManager.SystemDialogTip("", tips, XUiManager.DialogType.OnlySure, nil, function()
                    OnLogin(res.Code)
                end)
            else
                local msgtab = {}
                msgtab.retry_login_count = RetryLoginCount
                CS.XRecord.Record(msgtab, "24017", "DoLoginGameRequestError")
                RetryLoginCount = 0
                XLuaUiManager.ClearAnimationMask()
                XUiManager.SystemDialogTip("", CS.XTextManager.GetCodeText(res.Code), XUiManager.DialogType.OnlySure, nil, function()
                    OnLogin(res.Code)
                end)
            end
        else
            --BDC
            CS.XDateUtil.SetGameTimeZone(res.UtcOffset)
            if res.UtcServerTime and res.UtcServerTime ~= 0 then
                XTime.SyncTime(res.UtcServerTime, reqTime, SinceStartupTime())
            else
                XLog.Error("XNetwork.Call(LoginRequest) Error, UtcServerTime = " .. res.UtcServerTime)
            end
            CS.XHeroBdcAgent.BdcRoleLogin("2", CS.XTextManager.GetCodeText(res.Code))
            RetryLoginCount = 0
            ResetLoginOnServerFull()
            XUserManager.ReconnectedToken = res.ReconnectToken
            CS.XRecord.Record("24021", "LoginRequestSuccess")
        end
    end)
end


function XLoginManager.IsFirstOpenMainUi()
    return FirstOpenMainUi
end

function XLoginManager.IsStartGuide()
    return StartGuide
end

function XLoginManager.SetStartGuide(v)
    StartGuide = v
end

function XLoginManager.SetFirstOpenMainUi(flag)
    FirstOpenMainUi = flag
end

function XLoginManager.IsLogin()
    return IsLogin
end

-- 登陆接口
function XLoginManager.Login(cb)
    CS.XRecord.Record("24007", "InvokeLoginStart")
    if not IsRelogining then -- 游戏内重登不需要重载
        XDataCenter.Init()
        XMVCA:_HotReloadAll()
        XMVCA:Init()
    end

    LoginCb = cb

    XLoginManager.DoLogin(function(loginToken, ip, host, port)
        XLog.Debug(string.format("DoLogin cb - loginToken:%s, ip:%s, host:%s, port:%s, serverName:%s", loginToken, ip, host, port, XServerManager.GetCurServerName()))
        if host then
            XLog.Debug(host)
            local address = CS.System.Net.Dns.GetHostAddresses(host)
            XTool.LoopArray(address, function(v)
                if v.AddressFamily == CS.System.Net.Sockets.AddressFamily.InterNetwork then
                    ip = v:ToString()
                end
            end)
        end

        XNetwork.SetGateAddress(ip, port)
        LoginTokenCache = loginToken

        ---- 网关已连接，且与上次登录服务器相同
        if IsConnected and not XNetwork.CheckIsChangedGate() then
            XLoginManager.DoLoginGame(cb)
            return
        end

        ---- 网关已连接，切换了服务器
        if IsConnected then
            CS.XNetwork.Disconnect()
            IsConnected = false
        end

        if GateHandshakeTimer then
            XScheduleManager.UnSchedule(GateHandshakeTimer)
        end

        GateHandshakeTimer = XScheduleManager.ScheduleOnce(function()
            CS.XRecord.Record("24008", "GateHandShakeTimeOut")
            DoLoginTimeOut(cb)
        end, LoginTimeOutInterval)

        ConnectGate(function()
            XLoginManager.DoLoginGame(cb)
        end, false)
    end)
end

local OnCreateRole = function()
    XEventManager.DispatchEvent(XEventId.EVENT_NEW_PLAYER)
end

local function InitLimitLoginData(data)
    if data then
        LimitLoginQuiz = data.Quizs
    else
        LimitLoginQuiz = nil
    end
end

XRpc.NotifyLogin = function(data)
    CS.XRecord.Record("24022", "NotifyLogin")
    local loginProfiler = CS.XProfiler.Create("NotifyLogin")
    loginProfiler:Start()

    local playerProfiler = loginProfiler:CreateChild("XPlayer")
    playerProfiler:Start()
    XPlayer.Init(data.PlayerData)
    playerProfiler:Stop()

    CS.XRecord.SetRoleId(XPlayer.Id)
    CS.XRecord.RecordUserDeviceInfo()

    local itemProfiler = loginProfiler:CreateChild("ItemManager")
    itemProfiler:Start()
    XDataCenter.ItemManager.InitItemData(data.ItemList)
    XDataCenter.ItemManager.InitItemRecycle(data.ItemRecycleDict)
    itemProfiler:Stop()

    local characterProfiler = loginProfiler:CreateChild("CharacterManager")
    characterProfiler:Start()
    XDataCenter.CharacterManager.InitCharacters(data.CharacterList)
    local ag = XMVCA:GetAgency(ModuleId.XCharacter)
    ag:InitCharacters(data.CharacterList)
    characterProfiler:Stop()

    local equipProfiler = loginProfiler:CreateChild("EquipManager")
    equipProfiler:Start()
    XMVCA:GetAgency(ModuleId.XEquip):InitEquipData(data.EquipList)
    equipProfiler:Stop()

    local fashionProfiler = loginProfiler:CreateChild("FashionManager")
    fashionProfiler:Start()
    XDataCenter.FashionManager.InitFashions(data.FashionList)
    fashionProfiler:Stop()

    local baseEquipProfiler = loginProfiler:CreateChild("BaseEquipManager")
    baseEquipProfiler:Start()
    XDataCenter.BaseEquipManager.InitLoginData(data.BaseEquipLoginData)
    baseEquipProfiler:Stop()

    local fubenAssignProfiler = loginProfiler:CreateChild("FubenAssignManager")
    fubenAssignProfiler:Start()
    XDataCenter.FubenAssignManager.InitServerData(data.AssignChapterRecord)
    fubenAssignProfiler:Stop()

    local fubenProfiler = loginProfiler:CreateChild("FubenManager")
    fubenProfiler:Start()
    XDataCenter.FubenManager.InitFubenData(data.FubenData)
    fubenProfiler:Stop()

    local fubenMailLineProfiler = loginProfiler:CreateChild("FubenMainLineManager")
    fubenMailLineProfiler:Start()
    XDataCenter.FubenMainLineManager.InitFubenMainLineData(data.FubenMainLineData)
    fubenMailLineProfiler:Stop()

    local fubenExtraChapterProfiler = loginProfiler:CreateChild("FubenExtraChapterManager")
    fubenExtraChapterProfiler:Start()
    XDataCenter.ExtraChapterManager.InitExtraInfos(data.FubenChapterExtraLoginData)
    fubenExtraChapterProfiler:Stop()

    local fubenShortStoryChapterProfiler = loginProfiler:CreateChild("FubenShortStoryChapterManager")
    fubenShortStoryChapterProfiler:Start()
    XDataCenter.ShortStoryChapterManager.InitShortStoryInfos(data.FubenShortStoryLoginData)
    fubenShortStoryChapterProfiler:Stop()

    local fubenDailyProfiler = loginProfiler:CreateChild("FubenDailyManager")
    fubenDailyProfiler:Start()
    XDataCenter.FubenDailyManager.InitFubenDailyData(data.FubenDailyData)
    fubenDailyProfiler:Stop()

    local fubenUrgentEventProfiler = loginProfiler:CreateChild("FubenUrgentEventManager")
    fubenUrgentEventProfiler:Start()
    XDataCenter.FubenUrgentEventManager.InitData(data.FubenUrgentEventData)
    fubenUrgentEventProfiler:Stop()

    local autoFightProfiler = loginProfiler:CreateChild("AutoFightManager")
    autoFightProfiler:Start()
    XDataCenter.AutoFightManager.InitAutoFightData(data.AutoFightRecords)
    autoFightProfiler:Stop()

    local teamProfiler = loginProfiler:CreateChild("TeamManager")
    teamProfiler:Start()
    XDataCenter.TeamManager.InitTeamGroupData(data.TeamGroupData)
    XDataCenter.TeamManager.InitTeamPrefabData(data.TeamPrefabData)
    teamProfiler:Stop()

    local guildProfiler = loginProfiler:CreateChild("GuideManager")
    guildProfiler:Start()
    XDataCenter.GuideManager.InitGuideData(data.PlayerData.GuideData)
    guildProfiler:Stop()

    local functionOpenProfiler = loginProfiler:CreateChild("FunctionManager")
    functionOpenProfiler:Start()
    XFunctionManager.InitShieldFuncData(data.PlayerData.ShieldFuncList)
    XFunctionManager.InitFuncOpenTime(data.TimeLimitCtrlConfigList)
    functionOpenProfiler:Stop()

    local shareConfigProfiler = loginProfiler:CreateChild("PhotographManager")
    shareConfigProfiler:Start()
    XDataCenter.PhotographManager.InitSharePlatform(data.SharePlatformConfigList)
    shareConfigProfiler:Stop()

    local signInProfiler = loginProfiler:CreateChild("SignInManager")
    signInProfiler:Start()
    XDataCenter.SignInManager.InitData(data.SignInfos)
    signInProfiler:Stop()

    local fubenAssignProfiler2 = loginProfiler:CreateChild("FubenAssignManager")
    fubenAssignProfiler2:Start()
    XDataCenter.FubenAssignManager.UpdateChapterRecords(data.AssignChapterRecord)
    fubenAssignProfiler2:Stop()

    local headPortraitProfiler = loginProfiler:CreateChild("headPortraitProfiler")
    headPortraitProfiler:Start()
    XDataCenter.HeadPortraitManager.AsyncHeadPortraitInfos(data.HeadPortraitList, false)
    headPortraitProfiler:Stop()

    local dlcHuntProfiler = loginProfiler:CreateChild("DlcHuntProfiler")
    dlcHuntProfiler:Start()
    XDataCenter.DlcHuntManager.InitDataFromServer(data)
    dlcHuntProfiler:Stop()
    
    XDataCenter.PlanetManager.ClearEnableState()
    
    XDataCenter.WeaponFashionManager.InitWeaponFashions(data.WeaponFashionList)

    XDataCenter.PartnerManager.UpdatePartnerEntity(data.PartnerList)

    XDataCenter.PhotographManager.InitCurSceneId(data.UseBackgroundId)
    --BDC
    CS.XHeroBdcAgent.RoleId = data.PlayerData.Id
    CS.XHeroBdcAgent.RoleKey = data.PlayerData.ServerId .. "_" .. data.PlayerData.Id
    CS.XHeroBdcAgent.ServerId = data.PlayerData.ServerId
    local balance = XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.ActionPoint)
    local hongka = XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.HongKa)
    local heika = XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.FreeGem)
    local luomu = XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.Coin)
    CS.XHeroBdcAgent.BdcUserInfo(data.PlayerData.Name, data.PlayerData.Level, balance, hongka, heika, luomu)

    if (data.PlayerData.Flags & NEW_PLAYER_FLAG) == NEW_PLAYER_FLAG then
        -- new player
        OnCreateRole()
    end
    --设置协议屏蔽列表
    XNetwork.SetShieldedProtocolList(data.ShieldedProtocolList)
    -- 登录答题列表
    InitLimitLoginData(data.LimitedLoginData)
    XEventManager.DispatchEvent(XEventId.EVENT_LOGIN_DATA_LOAD_COMPLETE)

    local onloginProfiler = loginProfiler:CreateChild("OnLogin")
    onloginProfiler:Start()
    OnLogin()
    onloginProfiler:Stop()

    loginProfiler:Stop()
    XLog.Debug(loginProfiler);
end

function XLoginManager.Init()
    LoginErrCodeTemplate = XTableManager.ReadByIntKey(TableLoginErrCode, XTable.XTableLoginCode, "ErrCode")
    LoginProtectTemplate = XTableManager.ReadByIntKey(TableLoginProtect, XTable.XTableLoginProtect, "Id")
end

function XLoginManager.CheckLimitLogin()
    if LimitLoginQuiz and next(LimitLoginQuiz) then
        XLuaUiManager.Open("UiLoginVerification", LimitLoginQuiz)
        return true
    else
        return false
    end
end

function XLoginManager.ClearLimitLogin()
    LimitLoginQuiz = nil
    XEventManager.DispatchEvent(XEventId.EVENT_FUNCTION_EVENT_COMPLETE)
end

function XLoginManager.SendLoginVerify(quizIdx, answer, useTime, cb)
    if not quizIdx or not answer then return end
    XNetwork.Call("LimitedLoginVerifyRequest", { QuizIdx = quizIdx, Answer = answer, UseTime = useTime }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        cb(res.IsCorrect)
    end)
end

function XLoginManager.OnReconnectFailed()
    -- XLoginManager.DoDisconnect()
    if IsRelogining then
        if XNetwork.IsShowNetLog then
            XLog.Debug("已在断线重登。。。")
        end
        return
    end
    IsRelogining = true
    
    XLoginManager.Disconnect()
    XLoginManager.ClearAllTimer()

    XLuaUiManager.ClearAllMask(true)
    XLuaUiManager.SetAnimationMask("DoLogin", true, 1)

    if XFightUtil.IsFighting() then
        XLuaUiManager.Open("UiSettleLose")
        XFightUtil.ClearFight()
    end
    
    if XNetwork.IsShowNetLog then
        XLog.Debug("断线重连失败，尝试自动重登")
    end
    XLoginManager.Login(function(code) -- connecGate > onDisconnect > loginCb > connectGate
        XLuaUiManager.SetAnimationMask("DoLogin", false)
        if XNetwork.IsShowNetLog then
            XLog.Debug("断线重登，返回code:" .. tostring(code) .. ", IsLogin:" .. tostring(IsLogin))
        end
        if code and code ~= XCode.Success then
            --  弹窗返回登陆
            if code == XCode.Fail then
                code = XCode.ReconnectUnable
            end
            XUiManager.SystemDialogTip(CS.XTextManager.GetText("TipTitle"), CS.XTextManager.GetCodeText(code), XUiManager.DialogType.OnlySure, nil, XLoginManager.BackToLogin)
        else
            -- 重连成功
            XLoginManager.BackToMain() -- 默认关闭Normal上的所有UI，回到主界面。后续针对当前停留的ui来保留
        end
        IsRelogining = false
    end)
end

-- 加快心跳时间
function XLoginManager.SpeedUpHearbeatInterval()
    HeartbeatInterval = 200
    if HeartbeatNextTimer then -- 等待下一次心跳发送
        ClearHeartbeartTimer()
        DoHeartbeat()
    end
end

-- 重置默认心跳时间 ms
function XLoginManager.ResetHearbeatInterval()
    HeartbeatInterval = HeartbeatIntervalDefault
    XTime.ClearPingTime()
end

XRpc.ForceLogoutNotify = function(res)
    XLoginManager.Disconnect()
    CS.XFightNetwork.Disconnect()
    ClearHeartbeartTimer()
    XUiManager.SystemDialogTip(CS.XTextManager.GetText("TipTitle"), CS.XTextManager.GetCodeText(res.Code), XUiManager.DialogType.OnlySure, nil, function()
        XFightUtil.ClearFight()
        if XDataCenter.MovieManager then
            XDataCenter.MovieManager.StopMovie()
        end
        CS.Movie.XMovieManager.Instance:Clear()
        CsXUiManager.Instance:Clear()
        XHomeSceneManager.LeaveScene()

        XLuaUiManager.Open(UI_LOGIN)
    end)
end

XRpc.RpcErrorNotify = function(res)
    if res.Code ~= XCode.Success then
        XUiManager.TipCode(res.Code)
    end
end

XRpc.ShutdownNotify = function(res)
    XUserManager.ClearLoginData()
    XUiManager.TipError(CS.XTextManager.GetText("ServerShutdown"))
end

XRpc.LoginErrorNotify = function(res)
    XUiManager.SystemDialogTip(CS.XTextManager.GetText("TipTitle"), CS.XTextManager.GetText("ServerShutdown"), XUiManager.DialogType.OnlySure, nil, function()
        XUserManager.ClearLoginData()
    end)
end

XRpc.GameUpdateNotify = function(res)
    XLoginManager.Disconnect()
    CS.XFightNetwork.Disconnect()
    ClearHeartbeartTimer()

    XUiManager.SystemDialogTip(CS.XTextManager.GetText("TipTitle"), res.Msg, XUiManager.DialogType.OnlySure, nil, function()
        XFightUtil.ClearFight()
        if XDataCenter.MovieManager then
            XDataCenter.MovieManager.StopMovie()
        end

        if res.IsClientNeedUpdate then
            CS.XApplication.Exit()
        end

        CS.Movie.XMovieManager.Instance:Clear()
        CsXUiManager.Instance:Clear()
        XHomeSceneManager.LeaveScene()
        XLuaUiManager.Open(UI_LOGIN)
    end)
end

local test_id = 1
local tcp_time_table = {}
-- local kcp_time_table = {}
function XLoginManager.Test()
    local i = test_id
    test_id = test_id + 1

    local tcp_time = SinceStartupMilliSeconds()
    XNetwork.Call("Ping", { UtcTime = tcp_time }, function()
        local delta = SinceStartupMilliSeconds() - tcp_time

        if #tcp_time_table >= 10 then
            table.remove(tcp_time_table, 1)
        end
        table.insert(tcp_time_table, delta)

        local total = 0
        for _, v in ipairs(tcp_time_table) do
            total = total + v
        end
        local average = total / #tcp_time_table

        XLog.Error(string.format("+++++++++++++++++++++++++++++++++ tcp ping. id = %d, delta = %d, average = <color=red>%s</color>", i, delta, tostring(average)))
    end)
end