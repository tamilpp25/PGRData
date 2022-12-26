XFightNetwork = XFightNetwork or {}

local IsConnected = false

function XFightNetwork.IsConnected()
    return IsConnected
end

-- 心跳相关
local FightHeartbeatRequest = "FightHeartbeatRequest"
local HeartbeatTimeout = CS.XGame.Config:GetInt("FightHeartbeatTimeout")
local HeartbeatInterval = CS.XGame.Config:GetInt("FightHeartbeatInterval")
local HeartbeatTimer
XFightNetwork.DoHeartbeat = function()
    if not IsConnected then
        return
    end

    HeartbeatTimer = XScheduleManager.ScheduleOnce(function()
        if CS.XNetwork.IsShowNetLog then
            XLog.Debug("fight tcp heartbeat time out.")
        end
        -- 超时断开连接
        CS.XFightNetwork.Disconnect()
    end, HeartbeatTimeout)

    if CS.XFightNetwork.IsShowNetLog then
        XLog.Debug("fight tcp heartbeat request.")
    end
    XFightNetwork.Call(FightHeartbeatRequest, {}, function(res)
        XScheduleManager.UnSchedule(HeartbeatTimer)
        if CS.XFightNetwork.IsShowNetLog then
            XLog.Debug("fight tcp heartbeat response.")
        end
        if res.Code ~= XCode.Success then
            -- 心跳服务器返回错误，断开连接
            CS.XFightNetwork.Disconnect()
            return
        end
        HeartbeatTimer = XScheduleManager.ScheduleOnce(function()
            XFightNetwork.DoHeartbeat()
        end, HeartbeatInterval)
    end)
end

function XFightNetwork.Connect(ip, port, cb)
    if not ip or not port then
        XLog.Debug("Lua.XFightNetwork.Connect error, ip is nil or port is nil")
        return
    end

    -- 成功回调
    CS.XFightNetwork.OnConnect = function()
        XLog.Debug("Lua.XFightNetwork.Connect Success")
        IsConnected = true
        if cb then
            cb(true)
        end
    end

    -- 网络错误回调
    CS.XFightNetwork.OnError = function(socketError)
        XLog.Error("Lua.XFightNetwork.Connect error, " .. tostring(socketError:ToString()))
        CS.XFightNetwork.Disconnect()
        if cb then
            cb(false)
        end
    end

    CS.XFightNetwork.OnDisconnect = function()
        XLog.Debug("Lua.XFightNetwork.Connect OnDisconnect")
        IsConnected = false
    end

    CS.XFightNetwork.OnRemoteDisconnect = function()
        XLog.Error("Lua.XFightNetwork.Connect OnRemoteDisconnect")
        IsConnected = false
    end

    CS.XFightNetwork.OnMessageError = function()
        XLog.Error("Lua.XFightNetwork.Connect OnMessageError")
        CS.XFightNetwork.Disconnect()
    end

    CS.XFightNetwork.Connect(ip, tonumber(port))
end

local ConnectKcpTimer
local KcpConnectRequestInterval = 500
function XFightNetwork.ConnectKcp(ip, port, remoteConv, cb)
    XLog.Debug("Lua.XFightNetwork.ConnectKcp" .. " ip:" .. tostring(ip) .. " port:" .. tostring(port) .. " remoteConv:" .. tostring(remoteConv))
    CS.XFightNetwork.CreateUdpSession()
    local networkMode = XSaveTool.GetData(XNetwork.NetworkModeKey) or XNetwork.NetworkMode.Auto
    if networkMode == XNetwork.NetworkMode.Auto then
        CS.XFightNetwork.UdpConnect(ip, port, CS.XNetwork.NetworkMode.Auto)
    elseif networkMode == XNetwork.NetworkMode.Ipv4 then
        CS.XFightNetwork.UdpConnect(ip, port, CS.XNetwork.NetworkMode.Ipv4)
    elseif networkMode == XNetwork.NetworkMode.Ipv6 then
        CS.XFightNetwork.UdpConnect(ip, port, CS.XNetwork.NetworkMode.Ipv6)
    else -- Auto保底
        CS.XFightNetwork.UdpConnect(ip, port, CS.XNetwork.NetworkMode.Auto)
    end
    CS.XFightNetwork.CreateKcpSession(remoteConv)
    if ConnectKcpTimer then
        XScheduleManager.UnSchedule(ConnectKcpTimer)
        ConnectKcpTimer = nil
    end

    -- kcp握手请求
    local tryCount = 0
    local kcpConnected = false
    local startTime = CS.XDateUtil.GetTime()

    ConnectKcpTimer = XScheduleManager.ScheduleForever(function()
        -- 尝试次数超过10次且开始确认过去10秒
        if tryCount >= 10 and CS.XDateUtil.GetTime() - startTime >= 10 and not kcpConnected then
            CS.XFightNetwork.DisconnectKcp()
            XScheduleManager.UnSchedule(ConnectKcpTimer)
            ConnectKcpTimer = nil
            cb(false)
        end
        tryCount = tryCount + 1
        XLog.Debug("Lua.XFightNetwork.KcpConfirmRequest " .. tostring(tryCount))

        local requestContent = XMessagePack.Encode({})
        CS.XFightNetwork.CallKcp("KcpConfirmRequest", requestContent, function()
            XLog.Debug("KcpConfirmResponse")
            if not kcpConnected then
                XScheduleManager.UnSchedule(ConnectKcpTimer)
                ConnectKcpTimer = nil
                kcpConnected = true
                cb(true)
            end
        end)
    end, KcpConnectRequestInterval)
end

function XFightNetwork.Send(handler, request)
    local requestContent, error = XMessagePack.Encode(request)
    if requestContent == nil then
        XLog.Error("Lua.XFightNetwork.Send 函数错误, 客户端发送给服务端的数据编码处理失败, 失败原因：" .. error)
        return
    end

    CS.XFightNetwork.Send(handler, requestContent);
end

function XFightNetwork.Call(handler, request, reply)
    local requestContent, error = XMessagePack.Encode(request)
    if requestContent == nil then
        XLog.Error("Lua.XFightNetwork.Call 函数错误, 客户端发送给服务端的数据编码处理失败, 失败原因： " .. error)
        return
    end

    CS.XFightNetwork.Call(handler, requestContent, function(responseContent)
        local response, err = XMessagePack.Decode(responseContent)
        if response == nil then
            XLog.Error("Lua.XFightNetwork.Call 函数错误, 服务端返回的数据解码失败, 失败原因: " .. err)
            return
        end
        reply(response)
    end)
end

