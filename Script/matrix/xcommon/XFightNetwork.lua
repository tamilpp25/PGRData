XFightNetwork = XFightNetwork or {}

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

--region Dlc
function XFightNetwork.IsConnected()
    return CS.XFightNetwork.IsConnected
end

function XFightNetwork.Connect(ipAddress, port, cb, reconnect, disconnectCb)
    CS.XFightNetwork.Connect(ipAddress, port, cb, reconnect, disconnectCb)
end

function XFightNetwork.DoHeartbeat()
    CS.XFightNetwork.DoHeartbeat()
end

-- 心跳相关
local FightHeartbeatRequest = "FightHeartbeatRequest"
local HeartbeatTimeout = CS.XGame.Config:GetInt("FightHeartbeatTimeout")
local HeartbeatInterval = CS.XGame.Config:GetInt("FightHeartbeatInterval")
local HeartbeatTimer = nil

function XFightNetwork.DoDlcHearbeat()
    if not XFightNetwork.IsConnected() then
        return
    end
    
    HeartbeatTimer = XScheduleManager.ScheduleOnce(function()
        if CS.XNetwork.IsShowNetLog then
            XLog.Debug("fight tcp heartbeat time out.")
        end
        -- 超时断开连接
        XLog.Debug("[DlcHearbeatLog] Hearbeat TimeOut! Disconnect!")
        XFightNetwork.Disconnect()
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
            XLog.Debug("[DlcHearbeatLog] Dlc Fight Hearbeat Response Error! Disconnect!")
            XFightNetwork.Disconnect()
            return
        end
        HeartbeatTimer = XScheduleManager.ScheduleOnce(function()
            XFightNetwork.DoDlcHearbeat()
        end, HeartbeatInterval)
    end)
end

function XFightNetwork.ConnectKcp(ip, port, conv, cb)
    CS.XFightNetwork.ConnectKcp(ip, port, conv, cb)
end

function XFightNetwork.Disconnect()
    CS.XFightNetwork.Disconnect()
end

--endregion Dlc