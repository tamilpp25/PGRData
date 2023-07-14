XLoginManager = XLoginManager or {}

local Json = require("XCommon/Json")
local RetCode = {
    Success = 0,
    ErrServerMaintaining = 1, -- 服务器正常维护
    FirstLoginIsBanned = 11, -- 初次封禁
    MultiLoginIsBanned = 12, -- 多次封禁
}


local NEW_PLAYER_FLAG = 1 << 0
local SinceStartupTime = function() return CS.UnityEngine.Time.realtimeSinceStartup end
local SinceStartupMilliSeconds = function() return math.floor(CS.UnityEngine.Time.realtimeSinceStartup * 1000) end

local TableLoginErrCode = "Share/Login/LoginCode.tab"
local LoginErrCodeTemplate

-- 登陆token缓存
local LoginTokenCache

local UI_LOGIN = "UiLogin"
local LoginCb
local IsConnected = false
local IsLogin = false
local FirstOpenMainUi = false    --首次登陆成功打开主界面
local StartGuide = false --首次进入主界面播放完成动画后才能开始引导
local LimitLoginQuiz = {}
local HeartbeatInterval = CS.XGame.Config:GetInt("HeartbeatInterval")
local HeartbeatTimeout = CS.XGame.Config:GetInt("HeartbeatTimeout")
local HeartbeatTimer
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

-- 声明local方法
local DoReconnect
local DelayReconnect
local StartReconnect
local DoDisconnect
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

local ConnectGate = function(cb, bReconnect)
    cb = cb or function()
    end

    if IsConnected then
        cb()
        return
    end

    local args = {}
    args.ConnectCb = function()
        --BDC
        CS.XHeroBdcAgent.BdcServiceState(XServerManager.Id, "1")
        CS.XHeroBdcAgent.IntoGameTimeStart = CS.UnityEngine.Time.time
        IsConnected = true
        cb()
    end
    args.DisconnectCb = function()
        IsConnected = false
        -- IsRehandedKcp = false
        if LoginCb then
            LoginCb(XCode.Fail)
            LoginCb = nil
        end
    end
    args.ReconnectRequestFrequentlyCb = function()
        DelayReconnect()
    end
    args.RemoteDisconnectCb = function()
        DoReconnect()
    end
    args.ErrorCb = function(err)
        --BDC
        CS.XHeroBdcAgent.BdcServiceState(XServerManager.Id, "2")
        if err and (err ~= CS.System.Net.Sockets.SocketError.Success and err ~= CS.System.Net.Sockets.SocketError.OperationAborted) then
            local errStr = tostring(err:ToString())
            XLog.Warning("XNetwork.ConnectGateServer error. ============ SocketError." .. errStr)
            local msgtab = {}
            msgtab["error"] = errStr;
            local jsonStr = Json.encode(msgtab);
            CS.XRecord.Record(msgtab, "24013", "ConnectGateSeverSocketError")
            if LoginCb then
                XLuaUiManager.ClearAnimationMask()
                XUiManager.SystemDialogTip(CS.XTextManager.GetText("TipTitle"), CS.XTextManager.GetText("NetworkError"), XUiManager.DialogType.OnlySure, nil, nil)
                LoginCb(XCode.Fail)
                LoginCb = nil
            end
        end
    end
    args.MsgErrorCb = function()
        if ReconnectTimer then
            XScheduleManager.UnSchedule(ReconnectTimer)
        end
        if MaxReconnectTimer then
            XScheduleManager.UnSchedule(MaxReconnectTimer)
        end
        DoDisconnect()
    end
    args.IsReconnect = bReconnect
    args.RemoveHandshakeTimerCb = function()
        if GateHandshakeTimer then
            XScheduleManager.UnSchedule(GateHandshakeTimer)
        end
    end

    XNetwork.ConnectGateServer(args)
end

local Disconnect = function(bLogout)
    if HeartbeatTimer then
        XScheduleManager.UnSchedule(HeartbeatTimer)
        HeartbeatTimer = nil
    end

    CS.XNetwork.Disconnect()
    IsConnected = false

    if bLogout then
        IsLogin = false
    end

    if LoginCb then
        LoginCb(XCode.Fail)
        LoginCb = nil
    end

    XEventManager.DispatchEvent(XEventId.EVENT_NETWORK_DISCONNECT)
end

DoDisconnect = function()
    Disconnect(true)

    if LoginTimeOutTimer then
        XScheduleManager.UnSchedule(LoginTimeOutTimer)
        LoginTimeOutTimer = nil
    end

    if GateHandshakeTimer then
        XScheduleManager.UnSchedule(GateHandshakeTimer)
        GateHandshakeTimer = nil
    end

    if MaxReconnectTimer then
        XScheduleManager.UnSchedule(MaxReconnectTimer)
        MaxReconnectTimer = nil
    end

    if TcpPingTimer then
        XScheduleManager.UnSchedule(TcpPingTimer)
        TcpPingTimer = nil
    end

    XLuaUiManager.ClearAllMask(true)
    CS.XRecord.Record("24014", "SocketDisconnect")
    local function BackToLogin()
        if CS.XFight.Instance ~= nil then
            CS.XFight.ClearFight()
        end
        if XDataCenter.MovieManager then
            XDataCenter.MovieManager.StopMovie()
        end
        CS.Movie.XMovieManager.Instance:Clear()
        CsXUiManager.Instance:Clear()
        XHomeSceneManager.LeaveScene()
        CsXUiManager.Instance:Open(UI_LOGIN)
    end
    if XDataCenter.FunctionEventManager.CheckFuncDisable() then
        BackToLogin()
    else
        XUiManager.SystemDialogTip(CS.XTextManager.GetText("TipTitle"), CS.XTextManager.GetText("HeartbeatTimeout"), XUiManager.DialogType.OnlySure, nil, BackToLogin)
    end
end
XLoginManager.DoDisconnect = DoDisconnect

local DoHeartbeat
DoHeartbeat = function()
    if not IsLogin then
        return
    end

    HeartbeatTimer = XScheduleManager.ScheduleOnce(function()
        -- if CS.XNetwork.IsShowNetLog then
            XLog.Debug("tcp heartbeat time out.")
        -- end

        StartReconnect()
    end, HeartbeatTimeout)

    local reqTime = SinceStartupTime()
    if CS.XNetwork.IsShowNetLog then
        XLog.Debug("tcp heartbeat request.")
    end
    XNetwork.Call("HeartbeatRequest", nil, function(res)
        XTime.SyncTime(res.UtcServerTime, reqTime, SinceStartupTime())
        XScheduleManager.UnSchedule(HeartbeatTimer)
        if CS.XNetwork.IsShowNetLog then
            XLog.Debug("tcp heartbeat response.")
        end
        HeartbeatTimer = XScheduleManager.ScheduleOnce(function()
            DoHeartbeat()
        end, HeartbeatInterval)
    end)
end

function TestReconnect()
    StartReconnect()
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
            if CS.XNetwork.IsShowNetLog then
                XLog.Debug("超过服务器保留最长时间")
            end
            if HeartbeatTimer then
                XScheduleManager.UnSchedule(HeartbeatTimer)
                HeartbeatTimer = nil
            end
            XScheduleManager.UnSchedule(MaxReconnectTimer)
            DoDisconnect()
        end
    end, 1000)
    DoReconnect()
end

DelayReconnect = function()
    if CS.XNetwork.IsShowNetLog then
        XLog.Debug("重连频繁异常，延后再重连.")
    end

    if ReconnectTimer then
        XScheduleManager.UnSchedule(ReconnectTimer)
    end

    ReconnectTimer = XScheduleManager.ScheduleOnce(function()
        CS.XNetwork.Disconnect()
        DoReconnect()
    end, DelayReconnectTime)
end

-- 断线重连方法
DoReconnect = function()
    if not IsLogin then
        Disconnect(true)
        return
    end

    if not XUserManager.ReconnectedToken then
        DoDisconnect()
        return
    end

    ReconnectTimer = XScheduleManager.ScheduleOnce(function()
        -- if CS.XNetwork.IsShowNetLog then
            XLog.Debug("断线重连响应超时")
        -- end
        CS.XNetwork.Disconnect()
        DoReconnect()
    end, ReconnectInterval)

    if CS.XNetwork.IsShowNetLog then
        XLog.Debug("开始断线重连...")
    end
    Disconnect(false)
    --重连网关
    ConnectGate(function()
        XScheduleManager.UnSchedule(ReconnectTimer)
        -- if CS.XNetwork.IsShowNetLog then
            XLog.Debug("reconnect, then request heart beat.")
        -- end
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
    if CS.XNetwork.IsShowNetLog then
        XLog.Debug("login success, then request heart beat.")
    end
    DoMtpLogin(XUserManager.UserId, XUserManager.UserName)
    DoHeartbeat()
    StartTcpPingGate()
    XEventManager.DispatchEvent(XEventId.EVENT_LOGIN_SUCCESS)
end

-- KCP心跳
DoKcpHeartbeat = function()
    if not IsKcpConnected then
        return
    end

    KcpHeartbeatTimer = CS.XScheduleManager.Schedule(function()
        if not IsKcpConnected then
            return
        end

        -- if CS.XNetwork.IsShowNetLog then
            XLog.Debug("kcp heartbeat time out.")
        -- end

        if HeartbeatTimer then
            CS.XScheduleManager.UnSchedule(HeartbeatTimer)
            HeartbeatTimer = nil
        end

        StartReconnect()
    end, KcpHeartbeatTimeout, 1)

    if CS.XNetwork.IsShowNetLog then
        XLog.Debug("kcp heartbeat request.")
    end
    XNetwork.CallKcp("KcpHeartbeatRequest", nil, function()
        if CS.XNetwork.IsShowNetLog then
            XLog.Debug("kcp heartbeat response.")
        end
        if KcpHeartbeatTimer then
            CS.XScheduleManager.UnSchedule(KcpHeartbeatTimer)
            KcpHeartbeatTimer = nil
        end

        KcpHeartbeatTimer = CS.XScheduleManager.Schedule(function()
            DoKcpHeartbeat()
        end, KcpHeartbeatInterval, 1)
    end)
end

-- 创建KCP会话
CreateKcpSession = function(ip, port, remoteConv)
    --XLog.Debug("create kcp session. ip=" .. tostring(ip) .. ", port=" .. tostring(port) .. ", remoteConv=" .. tostring(remoteConv))
    IsKcpConnected = false
    CS.XNetwork.CreateUdpSession()
    CS.XNetwork.UdpConnect(ip, port)
    CS.XNetwork.CreateKcpSession(remoteConv)
    -- RemoteKcpConv = remoteConv

    if KcpHeartbeatTimer then
        CS.XScheduleManager.UnSchedule(KcpHeartbeatTimer)
        KcpHeartbeatTimer = nil
    end

    if CS.XNetwork.IsShowNetLog then
        XLog.Debug("kcp connect request.")
    end

    local tryCount = 0
    CS.XNetwork.KcpConnectRequest(remoteConv)
    KcpHeartbeatTimer = CS.XScheduleManager.Schedule(function()
        if not IsKcpConnected then
            if tryCount >= RetryKcpConnectCount then
                if not IsRehandedKcp then
                    IsRehandedKcp = true
                    --XNetwork.ConnectKcp(CreateKcpSession)
                end
                return
            end

            tryCount = tryCount + 1
            if CS.XNetwork.IsShowNetLog then
                XLog.Debug("kcp connect request retry.")
            end
            CS.XNetwork.KcpConnectRequest(remoteConv)
        end
    end, KcpConnectRequestInterval, 0)

    StartKcpPingGate()
end

local OnLogin = function(errCode)
    if LoginTimeOutTimer then
        XScheduleManager.UnSchedule(LoginTimeOutTimer)
    end

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
    Disconnect(true)
    XLuaUiManager.ClearAnimationMask()
    CS.XRecord.Record("24016", "DoLoginTimeOut")
    XUiManager.SystemDialogTip(CS.XTextManager.GetText("TipTitle"), CS.XTextManager.GetText("LoginTimeOut"), XUiManager.DialogType.Normal, function()
        OnLogin(XCode.Fail)
    end, function()
        XLoginManager.Login(cb)
    end)
end

local DoLogin
DoLogin = function(cb)
    -- if XUserManager.Channel == nil or
    -- XUserManager.UserId == nil then
    --     return
    -- end

    local loginUrl = XServerManager.GetLoginUrl() ..
    "?loginType=" .. XUserManager.Channel ..
    "&userId=" .. XUserManager.UserId ..
    "&token=" .. (XUserManager.Token or "") ..
    "&clientIp=" .. XLoginManager.ExIP

    --测试高防地址响应速度
    local beforeLoginTime = math.floor(CS.UnityEngine.Time.time * 1000);
    XLog.Debug("准备访问地址" .. XServerManager.GetLoginUrl() .. ", 当前时间(毫秒):" .. beforeLoginTime);

    local request = CS.UnityEngine.Networking.UnityWebRequest.Get(loginUrl)
    request.timeout = LoginTimeOutSecond
    CS.XRecord.Record("24009", "RequestLoginHttpSever")
    -- XLuaUiManager.SetAnimationMask("RequestLoginHttpSever", true)
    CS.XUiManager.Instance:SetAnimationMask(true);
    CS.XTool.WaitNativeCoroutine(request:SendWebRequest(), function()
        if request.isNetworkError then
            XLog.Error("login network error，url is " .. loginUrl .. ", message is " .. request.error)
            -- XLuaUiManager.SetAnimationMask("RequestLoginHttpSever", false)
            XLuaUiManager.ClearAnimationMask()
            XUiManager.SystemDialogTip("", LoginNetworkError, XUiManager.DialogType.OnlySure, nil, function()
                if LoginCb then
                    LoginCb(XCode.Fail)
                    LoginCb = nil
                end
            end)
            CS.XRecord.Record("24010", "RequestLoginHttpSeverNetWorkError")
            return
        end

        if request.isHttpError then
            XLog.Error("login http error，url is " .. loginUrl .. ", message is " .. request.error)
            XLuaUiManager.SetAnimationMask("RequestLoginHttpSever", false)
            XLuaUiManager.ClearAnimationMask()
            XUiManager.SystemDialogTip("", LoginHttpError, XUiManager.DialogType.OnlySure, nil, function()
                if LoginCb then
                    LoginCb(XCode.Fail)
                    LoginCb = nil
                end
            end)
            CS.XRecord.Record("24011", "RequestLoginHttpSeverHttpError")
            return
        end

        local result = Json.decode(request.downloadHandler.text)
        if result.code ~= RetCode.Success then
            local tipMsg

            if result.code == RetCode.ErrServerMaintaining then
                tipMsg = result.msg
            elseif result.code == RetCode.FirstLoginIsBanned or result.code == RetCode.MultiLoginIsBanned then
                local template = LoginErrCodeTemplate[result.code]
                local timeStr = os.date("%Y-%m-%d %H:%M:%S", result.loginLockTime)
                tipMsg = string.format(template.Msg, result.playerId, result.reason, timeStr)
            else
                local template = LoginErrCodeTemplate[result.code]
                if template then
                    tipMsg = template.Msg
                else
                    tipMsg = "login errCode is " .. result.code
                end
            end

            -- XLuaUiManager.SetAnimationMask("RequestLoginHttpSever", false)
            XLuaUiManager.ClearAnimationMask()
            XLuaUiManager.Open("UiAssertDialog", "", tipMsg, nil, nil, function()
                if LoginCb then
                    LoginCb(XCode.Fail)
                    LoginCb = nil
                end
            end)
            CS.XRecord.Record("24012", "RequestLoginHttpSeverLoginError")
            return
        end

        -- XLuaUiManager.SetAnimationMask("RequestLoginHttpSever", false)
        CS.XUiManager.Instance:SetAnimationMask(false);
        CS.XRecord.Record("24031", "RequestLoginHttpSeverLoginSuccess")

        local afterLoginTime = math.floor(CS.UnityEngine.Time.time * 1000);
        XLog.Debug("高防地址返回成功, 当前时间(毫秒):" .. afterLoginTime .. "共用时:" .. (afterLoginTime - beforeLoginTime) .. "ms");

        if cb then
            cb(result.token, result.ip, result.host, result.port)
        end

        request:Dispose()
    end)
end

local DoLoginGame
DoLoginGame = function(cb)
    if LoginTimeOutTimer then
        XScheduleManager.UnSchedule(LoginTimeOutTimer)
    end

    LoginTimeOutTimer = XScheduleManager.ScheduleOnce(function()
        DoLoginTimeOut(cb)
    end, LoginTimeOutInterval)

    XLog.Debug("login platform is " .. XUserManager.Platform)

    local reqTime = SinceStartupTime()
    -- local ServerBean = CS.XHeroBdcAgent.GetServerBean()
    local serverBeanStr = CS.XHeroBdcAgent.GetServerBeanStr();
    XNetwork.Call("LoginRequest", {
        LoginType = XUserManager.Channel,
        LoginPlatform = XUserManager.Platform,
        UserId = XUserManager.UserId,
        -- ProjectId = CS.XHeroSdkAgent.GetAppProjectId(),
        Token = LoginTokenCache,
        DeviceId = CS.XHeroBdcAgent.GetDeviceId(),
        -- OaId = CS.XHeroSdkAgent.OAID,
        ClientVersion = CS.XRemoteConfig.DocumentVersion,
        ServerBean = serverBeanStr,
    }, function(res)
        if res.Code ~= XCode.Success then
            --BDC
            CS.XHeroBdcAgent.BdcRoleLogin("2", CS.XTextManager.GetCodeText(res.Code))
            if res.Code == XCode.LoginServiceRetry and RetryLoginCount < RETRY_LOGIN_MAX_COUNT then
                RetryLoginCount = RetryLoginCount + 1
                local msgtab = {}
                msgtab["retry_login_count"] = tostring(RetryLoginCount)
                CS.XRecord.Record(msgtab, "24017", "DoLoginGameRequestError")
                DoLoginGame(cb)
            else
                local msgtab = {}
                msgtab["retry_login_count"] = tostring(RetryLoginCount)
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
            -- XHgSdkManager.setServerBeanTmp(ServerBean)
            if res.UtcServerTime and res.UtcServerTime ~= 0 then
                XTime.SyncTime(res.UtcServerTime, reqTime, SinceStartupTime())
            else
                XLog.Error("XNetwork.Call(LoginRequest) Error, UtcServerTime = " .. res.UtcServerTime)
            end
            CS.XHeroBdcAgent.BdcRoleLogin("1", "")
            RetryLoginCount = 0
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

function XLoginManager.Login(cb)
    CS.XRecord.Record("24007", "InvokeLoginStart")
    XLoginManager.ExIP = XDataCenter.NoticeManager.GetIp()
    CS.XDateUtil.SetGameTimeZone(0) --英文服特殊处理，强行把时区设置为零时区，防止在manager初始化时使用本地时区初始化时间戳
    XDataCenter.Init()

    LoginCb = cb

    DoLogin(function(loginToken, ip, host, port)
        XLog.Debug(loginToken, ip, host, port)
        if host then
            XLog.Debug(host)
            local address = CS.System.Net.Dns.GetHostAddresses(host)
            XTool.LoopArray(address, function(v)
                if v.AddressFamily == CS.System.Net.Sockets.AddressFamily.InterNetwork then
                    ip = v:ToString()
                end
            end)
        end

        XLog.Debug(loginToken, ip, port)
        XNetwork.SetGateAddress(ip, port)
        LoginTokenCache = loginToken

        ---- 网关已连接，且与上次登录服务器相同
        if IsConnected and not XNetwork.CheckIsChangedGate() then
            DoLoginGame(cb)
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
            DoLoginGame(cb)
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

    local itemProfiler = loginProfiler:CreateChild("ItemManager")
    itemProfiler:Start()
    XDataCenter.ItemManager.InitItemData(data.ItemList)
    XDataCenter.ItemManager.InitItemRecycle(data.ItemRecycleDict)
    XDataCenter.ItemManager.InitBatchItemRecycle(data.BatchItemRecycle)
    itemProfiler:Stop()

    local characterProfiler = loginProfiler:CreateChild("CharacterManager")
    characterProfiler:Start()
    XDataCenter.CharacterManager.InitCharacters(data.CharacterList)
    characterProfiler:Stop()

    local equipProfiler = loginProfiler:CreateChild("EquipManager")
    equipProfiler:Start()
    XDataCenter.EquipManager.InitEquipData(data.EquipList)
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

    XDataCenter.WeaponFashionManager.InitWeaponFashions(data.WeaponFashionList)

    XDataCenter.PartnerManager.UpdatePartnerEntity(data.PartnerList)
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
    --XNetwork.SetShieldedProtocolList(data.ShieldedProtocolList)
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

function XLoginManager.Disconnect()
    Disconnect(true)
end

function XLoginManager.Init()
    LoginErrCodeTemplate = XTableManager.ReadByIntKey(TableLoginErrCode, XTable.XTableLoginCode, "ErrCode")
end

function XLoginManager.SetUserType(usertype)
    XSaveTool.SaveData(XPrefs.UserType,usertype)
end

function XLoginManager.CleanUserType()
    XSaveTool.RemoveData(XPrefs.UserType)
end
function XLoginManager.GetUserType()
    return XSaveTool.GetData(XPrefs.UserType)
end

function XLoginManager.SetUserId(uid)
    XSaveTool.SaveData(XPrefs.UserId,uid)
end

function XLoginManager.CleanUserId()
    XSaveTool.RemoveData(XPrefs.UserId)
end

function XLoginManager.GetUserId()
    return XSaveTool.GetData(XPrefs.UserId)
end

function XLoginManager.SetToken(token)
    XSaveTool.SaveData(XPrefs.Token,token)
end

function XLoginManager.CleanToken()
    XSaveTool.RemoveData(XPrefs.Token)
end

function XLoginManager.GetToken()
    return XSaveTool.GetData(XPrefs.Token)
end

function XLoginManager.SetPasswordStatus(pwdStatus)
    XSaveTool.SaveData(XPrefs.PasswordStatus, pwdStatus)
end

function XLoginManager.CleanPasswordStatus()
    XSaveTool.RemoveData(XPrefs.PasswordStatus)
end

function XLoginManager.GetPasswordStatus()
    return XSaveTool.GetData(XPrefs.PasswordStatus)
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
    XNetwork.Call("LimitedLoginVerifyRequest", {QuizIdx = quizIdx, Answer = answer, UseTime = useTime }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        cb(res.IsCorrect)
    end)
end

XRpc.ForceLogoutNotify = function(res)
    Disconnect(true)
    CS.XFightNetwork.Disconnect()
    XScheduleManager.UnSchedule(HeartbeatTimer)
    XUiManager.SystemDialogTip(CS.XTextManager.GetText("TipTitle"), CS.XTextManager.GetCodeText(res.Code), XUiManager.DialogType.OnlySure, nil, function()
        if CS.XFight.Instance ~= nil then
            CS.XFight.ClearFight()
        end
        if XDataCenter.MovieManager then
            XDataCenter.MovieManager.StopMovie()
        end
        if XDataCenter.PokemonManager then
            XDataCenter.PokemonManager.ResetSpeed()
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

XLoginManager.SDKAccountStatus = {
    Normal = 0, -- 正常账号
    Cancellation = 1, -- 注销中账号
}
local CurSDKAccountStatus = 0

function XLoginManager.GetSDKAccountStatus()
    XLog.Debug("获取SDK账号注销状态:"..tostring(CurSDKAccountStatus))
    return CurSDKAccountStatus
end

function XLoginManager.SetSDKAccountStatus(status)
    XLog.Debug("设置SDK账号注销状态:"..tostring(status))
    CurSDKAccountStatus = status
end